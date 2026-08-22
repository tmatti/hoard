# Chapter 4: thread-per-run versus task-per-run at realistic scale.
# N agent runs, each: turn 0 LLM (0.2s) + 4 tools (0.1s, fanned out),
# turn 1 same, turn 2 LLM only. Ideal single-run latency: 0.8s.
# Thread design: one thread per run, one thread per tool call.
# Fiber design: one task per run, tool calls as tasks under a semaphore.
# Both hit the same fake LLM server over plain HTTP with identical payloads.
# Measures wall time, per-run latency distribution, RSS growth, and
# native threads created.

require "async"
require "async/barrier"
require "async/semaphore"
require_relative "support"

N = Integer(ENV.fetch("N", 400))

begin
  Process.setrlimit(:NOFILE, 65536)
rescue Errno::EPERM
  puts "could not raise NOFILE; current #{Process.getrlimit(:NOFILE).inspect}"
end

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}, N=#{N} runs"

LLM_LATENCY = 0.2
TOOL_LATENCY = 0.1

def llm_turn(port, run, turn)
  status, body = post_json(port, "/v1/chat", {run:, turn:, latency: LLM_LATENCY, tools: 4})
  raise "LLM #{status}" unless status == 200
  body
end

def tool(port, tc)
  post_json(port, "/v1/tool", {name: tc["name"], latency: TOOL_LATENCY}).last
end

def percentile(sorted, p) = sorted[(sorted.size * p).floor.clamp(0, sorted.size - 1)]

def report(label, wall, durations, rss, threads_created)
  s = durations.sort
  puts format("  %-8s wall %5.2fs  run p50 %.2fs  p99 %.2fs  max %.2fs  RSS +%d KB  native threads created: %d",
              label, wall, percentile(s, 0.5), percentile(s, 0.99), s.max, rss, threads_created)
end

def thread_count_baseline
  Dir.children("/proc/self/task").size
end

with_fake_llm do |port|
  # --- thread-per-run ---
  GC.start
  base_rss = rss_kb
  durations = []
  mutex = Mutex.new
  threads_before = thread_count_baseline
  peak_threads = 0
  monitor = Thread.new { loop { peak_threads = [peak_threads, thread_count_baseline].max; sleep 0.05 } }
  created = N # run threads; tool threads counted below
  t0 = now
  runners = N.times.map do |run|
    Thread.new do
      r0 = now
      3.times do |turn|
        response = llm_turn(port, run, turn)
        if (tcs = response["tool_calls"])
          tool_threads = tcs.map { |tc| Thread.new { tool(port, tc) } }
          mutex.synchronize { created += tool_threads.size }
          tool_threads.each(&:join)
        end
      end
      mutex.synchronize { durations << now - r0 }
    end
  end
  runners.each(&:join)
  wall = now - t0
  monitor.kill
  report("threads:", wall, durations, rss_kb - base_rss, created)
  puts format("           peak native threads alive: %d (baseline %d)", peak_threads, threads_before)

  sleep 1
  GC.start
  sleep 1

  # --- task-per-run ---
  base_rss = rss_kb
  durations = []
  threads_before = thread_count_baseline
  t0 = now
  Sync do |task|
    runners = N.times.map do |run|
      task.async do
        r0 = now
        3.times do |turn|
          response = llm_turn(port, run, turn)
          if (tcs = response["tool_calls"])
            barrier = Async::Barrier.new
            semaphore = Async::Semaphore.new(8, parent: barrier)
            tcs.each { |tc| semaphore.async { tool(port, tc) } }
            barrier.wait
          end
        end
        durations << now - r0
      end
    end
    runners.each(&:wait)
  end
  wall = now - t0
  report("tasks:", wall, durations, rss_kb - base_rss, thread_count_baseline - threads_before)
end
