# Chapter 4: the canonical agent loop on fibers.
# One task per run. The run's turns are plain sequential code. Tool calls
# fan out as child tasks under a barrier, capped by a semaphore. Each turn
# has a deadline via with_timeout. The LLM call retries with backoff, and
# the backoff sleep parks the fiber instead of holding a thread.
#
# Runs 3 agents concurrently against the fake LLM (0.2s per LLM call,
# 0.1s per tool call) and prints a timestamped event log for run 0.

require "async"
require "async/barrier"
require "async/semaphore"
require_relative "support"

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}"

LLM_LATENCY  = 0.2
TOOL_LATENCY = 0.1
TURN_DEADLINE = 2.0
MAX_TOOL_CONCURRENCY = 8

$t0 = nil
def log(run, msg)
  puts format("  [%5.2fs] run %d: %s", now - $t0, run, msg) if run.zero?
end

def call_llm(port, run:, turn:, flaky: false)
  attempts = 0
  begin
    attempts += 1
    payload = {run:, turn:, latency: LLM_LATENCY, tools: 4}
    payload[:flaky_key] = "run#{run}-turn#{turn}" if flaky
    status, body = post_json(port, "/v1/chat", payload)
    raise "LLM returned #{status}" if status != 200
    log(run, "LLM turn #{turn} ok after #{attempts} attempt(s)")
    body
  rescue => e
    raise if attempts >= 3
    backoff = 0.1 * (2 ** (attempts - 1))
    log(run, "LLM error (#{e.message}), retrying in #{backoff}s")
    sleep backoff       # parks the fiber; other runs keep going
    retry
  end
end

def call_tool(port, run, tool_call)
  _, body = post_json(port, "/v1/tool", {name: tool_call["name"], latency: TOOL_LATENCY})
  {tool_call_id: tool_call["id"], content: body["result"]}
end

def run_agent(port, run, task: Async::Task.current)
  messages = [{role: "user", content: "do the thing"}]
  turn = 0
  loop do
    response = task.with_timeout(TURN_DEADLINE) do
      # Make turn 1 of run 0 fail once so the retry path shows in the log.
      call_llm(port, run:, turn:, flaky: run.zero? && turn == 1)
    end

    if (tool_calls = response["tool_calls"])
      log(run, "fan out #{tool_calls.size} tool calls")
      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(MAX_TOOL_CONCURRENCY, parent: barrier)
      result_tasks = tool_calls.map { |tc| semaphore.async { call_tool(port, run, tc) } }
      barrier.wait
      messages.concat(result_tasks.map(&:wait).map { |r| {role: "tool", **r} })
      log(run, "tools done")
      turn += 1
    else
      log(run, "final: #{response["content"].inspect}")
      return response["content"]
    end
  end
end

with_fake_llm do |port|
  $t0 = now
  Sync do |task|
    runs = 3.times.map { |i| task.async { run_agent(port, i) } }
    answers = runs.map(&:wait)
    puts "  all runs done in #{(now - $t0).round(2)}s: #{answers.inspect}"
  end
end
