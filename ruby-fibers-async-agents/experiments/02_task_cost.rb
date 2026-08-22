# Chapter 2: what a task costs versus a thread.
# Creates N sleeping threads, then N parked async tasks, measuring wall-clock
# creation time and resident memory growth for each.

require "async"

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}"

N = Integer(ENV.fetch("N", 5000))

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

def rss_kb
  File.read("/proc/self/status")[/VmRSS:\s+(\d+)/, 1].to_i
end

GC.start
base = rss_kb

# --- threads ---
t0 = now
threads = N.times.map { Thread.new { sleep } }
thread_create = now - t0
sleep 0.5 # let them all actually start and block
thread_rss = rss_kb - base

threads.each(&:kill)
threads.each(&:join)
GC.start
sleep 0.5
base = rss_kb

# --- tasks ---
task_create = nil
task_rss = nil
Sync do |parent|
  t0 = now
  tasks = N.times.map { parent.async { sleep } }
  task_create = now - t0
  sleep 0.5
  task_rss = rss_kb - base
  tasks.each(&:stop)
end

puts
puts format("%d of each:", N)
puts format("  threads: created in %.3fs (%.1f us each), RSS grew %d KB (%.1f KB each)",
            thread_create, thread_create / N * 1e6, thread_rss, thread_rss.to_f / N)
puts format("  tasks:   created in %.3fs (%.1f us each), RSS grew %d KB (%.1f KB each)",
            task_create, task_create / N * 1e6, task_rss, task_rss.to_f / N)
