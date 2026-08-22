# Chapter 6: pitfalls, each demonstrated rather than asserted.
# A: CPU work starves the reactor (measured heartbeat gap).
# B: Timeout.timeout inside a reactor, versus task.with_timeout. On Ruby 4,
#    timeout.rb delegates to scheduler.timeout_after when a scheduler is set,
#    so the old thread-raise behaviour only survives OUTSIDE the reactor; the
#    remaining trap is that no timeout can interrupt a blocking C call.
# C: Thread.current[] is fiber-local; thread variables and Fiber[] differ.
# D: no data races without threads, but lost updates across await points.
# E: forgetting barrier.wait: invisible errors; forgotten children delay exit.
# F: deterministic async tests: inject the transport, zero latency, repeat.

require "async"
require "async/barrier"
require "timeout"

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}"

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

puts "\n== A: CPU starves the reactor =="
Sync do |task|
  gaps = []
  last = now
  hb = task.async { loop { sleep 0.02; gaps << now - last; last = now } }
  sleep 0.1
  x = 0
  30_000_000.times { x += 1 }          # ~1s of pure Ruby CPU, no yield points
  sleep 0.1
  hb.stop
  puts format("  30M iterations of x += 1 ran on the reactor; worst heartbeat gap %.0fms (target 20ms)", gaps.max * 1000)
end

puts "\n== B: Timeout.timeout vs task.with_timeout =="
Sync do |task|
  t0 = now
  begin
    Timeout.timeout(0.3) { sleep 5 }
    puts "  Timeout.timeout(0.3) around sleep(5): returned normally?!"
  rescue Timeout::Error
    puts format("  Timeout.timeout(0.3) around sleep(5): Timeout::Error after %.2fs", now - t0)
  end

  t0 = now
  begin
    Timeout.timeout(0.3) { Fiber.blocking { sleep 1 } }
    puts format("  Timeout.timeout(0.3) around a BLOCKING sleep(1): no error, returned after %.2fs", now - t0)
  rescue Timeout::Error
    puts format("  Timeout.timeout(0.3) around a BLOCKING sleep(1): Timeout::Error after %.2fs", now - t0)
  end

  t0 = now
  begin
    task.with_timeout(0.3) { sleep 5 }
  rescue Async::TimeoutError
    puts format("  task.with_timeout(0.3) around sleep(5): Async::TimeoutError after %.2fs", now - t0)
  end
end

puts "\n== B2: does Timeout.timeout hit an innocent bystander? =="
# Under threads, Timeout's monitor thread calls Thread#raise, which lands in
# whatever code the thread is running when the timer fires. Inside a reactor,
# Ruby 4's timeout.rb (line 284) delegates to scheduler.timeout_after instead,
# so the exception should stay in the fiber that armed it. Task A arms a 0.35s
# timeout and parks; task B chews CPU in 100ms slices and would be the fiber
# on the CPU when the timer fires.
Sync do |task|
  victim = nil
  a = task.async do
    Timeout.timeout(0.35) { sleep 5 }
    :a_finished
  rescue Timeout::Error
    :a_timed_out
  end
  b = task.async do
    10.times { t = now; nil while now - t < 0.1; sleep 0.001 }
    :b_finished
  rescue Exception => e
    victim = e
    :b_killed
  end
  results = [a.wait, b.wait]
  puts "  task A (armed the timeout): #{results[0].inspect}"
  puts "  task B (innocent CPU work): #{results[1].inspect}, caught #{victim.class}: #{victim&.message.inspect}"
end

puts "\n== C: fiber-local vs thread-local vs Fiber[] =="
Sync do |task|
  Thread.current[:tenant] = "from-parent-fiber"
  Thread.current.thread_variable_set(:tenant, "true-thread-local")
  Fiber[:tenant] = "fiber-storage"

  task.async do
    puts "  in child task:"
    puts "    Thread.current[:tenant]              = #{Thread.current[:tenant].inspect}   (fiber-local: child fiber starts empty)"
    puts "    Thread.current.thread_variable_get   = #{Thread.current.thread_variable_get(:tenant).inspect}   (shared by every fiber on the thread)"
    puts "    Fiber[:tenant]                       = #{Fiber[:tenant].inspect}   (inherited by child fibers)"
  end.wait
end

puts "\n== D: atomicity: single ops fine, lost updates across awaits =="
Sync do |task|
  counter = 0
  10.times.map { task.async { 100.times { counter += 1 } } }.each(&:wait)
  puts "  10 tasks x 100 bare increments: #{counter}/1000 (no preemption between yield points)"

  counter = 0
  10.times.map do
    task.async do
      100.times do
        v = counter
        sleep 0.0001        # an await between read and write, like an HTTP call
        counter = v + 1
      end
    end
  end.each(&:wait)
  puts "  same, with an await between read and write: #{counter}/1000 (lost updates, no threads involved)"
end

puts "\n== E: forgetting the wait =="

def fire_and_forget_tools(task)
  barrier = Async::Barrier.new
  3.times { |i| barrier.async { raise "tool #{i} failed" if i == 1 } }
  # bug: no barrier.wait
end

Sync do |task|
  fire_and_forget_tools(task)
  sleep 0.05
  puts "  spawned 3 tools, one raised, caller saw nothing (error went to the console logger above)"
end

t0 = now
Sync do |task|
  task.async { sleep 1 }    # forgotten child, nobody waits on it
  # method "returns" here
end
puts format("  Sync block with a forgotten sleeping child returned after %.2fs: the reactor won't abandon it", now - t0)

puts "\n== F: deterministic tests: inject the transport =="

# The agent turn logic from ch. 4, with the HTTP layer injected as a lambda.
def run_turn(llm, tools:, events:)
  response = llm.call
  if (tcs = response[:tool_calls])
    barrier = Async::Barrier.new
    tcs.each { |tc| barrier.async { events << tools.call(tc) } }
    barrier.wait
    :continue
  else
    events << response[:content]
    :done
  end
end

runs = 3.times.map do
  events = []
  t0 = now
  Sync do
    run_turn(-> { {tool_calls: [{id: "a"}, {id: "b"}]} }, tools: ->(tc) { "ran #{tc[:id]}" }, events:)
    run_turn(-> { {content: "final"} }, tools: nil, events:)
  end
  [events, now - t0]
end

identical = runs.map(&:first).uniq.size == 1
puts "  3 runs, events #{runs.first.first.inspect}"
puts format("  identical across runs: %s, mean duration %.2fms (no server, no sleeps, no flakes)",
            identical, runs.sum { |_, d| d } / 3 * 1000)
