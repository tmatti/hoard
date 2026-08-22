# Chapter 5: the seams.
# A: a driver that blocks in C (simulated with Fiber.blocking) stalls every
#    fiber in the reactor. Eight 50ms "queries" serialize to 400ms and the
#    heartbeat freezes for the duration.
# B: the escape hatch: run the blocking call on a thread, park the fiber on
#    Thread::Queue#pop. Same eight queries overlap, heartbeat stays alive.
# C: an outbound event publisher as a task: bounded queue, batching,
#    backpressure on the producer, and terminal events that survive
#    cancellation of the run that produced them.

require "async"

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}"

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

def with_heartbeat(task)
  gaps = []
  last = now
  hb = task.async do
    loop do
      sleep 0.02
      gaps << now - last
      last = now
    end
  end
  result = yield
  hb.stop
  [result, gaps.max * 1000]
end

QUERIES = 8
QUERY_TIME = 0.05

puts "\n== A: blocking driver in the reactor =="
Sync do |task|
  _, max_gap = with_heartbeat(task) do
    t0 = now
    tasks = QUERIES.times.map do
      task.async do
        Fiber.blocking { sleep QUERY_TIME }   # what mysql2 etc. do to the reactor
      end
    end
    tasks.each(&:wait)
    puts format("  %d x %dms blocking queries: %.2fs wall (fully serialized)", QUERIES, QUERY_TIME * 1000, now - t0)
  end
  puts format("  worst heartbeat gap: %.0fms (should be ~20ms)", max_gap)
end

puts "\n== B: offload to a thread, park the fiber on Queue#pop =="

def offload
  queue = Thread::Queue.new
  Thread.new do
    queue << begin
      [:ok, yield]
    rescue Exception => e
      [:error, e]
    end
  end
  tag, value = queue.pop      # Queue#pop is scheduler-aware: parks this fiber
  raise value if tag == :error
  value
end

Sync do |task|
  _, max_gap = with_heartbeat(task) do
    t0 = now
    tasks = QUERIES.times.map do
      task.async { offload { Fiber.blocking { sleep QUERY_TIME } } }
    end
    tasks.each(&:wait)
    puts format("  same %d queries via offload: %.2fs wall (overlapped)", QUERIES, now - t0)
  end
  puts format("  worst heartbeat gap: %.0fms", max_gap)
end

def spawn_publisher(task, events, published, batches)
  task.async do
    loop do
      first = events.dequeue
      batch = [first]
      batch << events.dequeue while !events.empty? && batch.size < 10
      sleep 0.02                       # simulated publish round-trip
      published.concat(batch)
      batches << batch.size
      break if batch.include?(:run_terminal)
    end
  end
end

puts "\n== C1: publisher with batching and backpressure =="
Sync do |task|
  events = Async::LimitedQueue.new(16)
  published, batches = [], []
  publisher = spawn_publisher(task, events, published, batches)

  blocked = 0.0
  60.times do |i|
    t = now
    events << "event-#{i}"             # blocks when the queue is full
    blocked += now - t
  end
  events << :run_terminal
  publisher.wait
  puts format("  producer emitted 60 events, spent %.0fms blocked on the full queue (backpressure, nothing dropped)", blocked * 1000)
  puts "  publisher sent #{published.size} events in batches of #{batches.inspect}"
end

puts "\n== C2: terminal event survives cancelling the run =="
Sync do |task|
  events = Async::LimitedQueue.new(16)
  published, batches = [], []
  publisher = spawn_publisher(task, events, published, batches)

  emitted = 0
  producer = task.async do
    1000.times { |i| events << "event-#{i}"; emitted += 1 }
  ensure
    events << :run_terminal            # runs even when the task is cancelled
  end

  sleep 0.05
  producer.stop                        # cancel the run mid-flight
  publisher.wait                       # publisher drains up to the terminal
  puts "  run cancelled after #{emitted} of 1000 events; publisher still delivered #{published.size} incl. terminal: #{published.include?(:run_terminal)}"
end
