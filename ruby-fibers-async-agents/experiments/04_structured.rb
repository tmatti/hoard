# Chapter 3: structured concurrency.
# A: Barrier collects a fan-out.
# B: Semaphore caps concurrency: 32 fake tool calls, 8 in flight, 0.25s each.
# C: with_timeout puts a deadline on a turn.
# D: stop propagates down a task tree; ensure runs in stopped tasks mid-I/O.
# E: an error in one child, surfaced by barrier.wait, cancels its siblings.

require "async"
require "async/barrier"
require "async/semaphore"

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}"

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

puts "\n== A: barrier =="
Sync do
  barrier = Async::Barrier.new
  results = 5.times.map { |i| barrier.async { sleep 0.1; "tool-#{i}" } }
  barrier.wait
  puts "  collected: #{results.map(&:wait).inspect}"
end

puts "\n== B: semaphore, 32 calls, 8 slots, 0.25s each =="
Sync do
  in_flight = 0
  peak = 0
  barrier = Async::Barrier.new
  semaphore = Async::Semaphore.new(8, parent: barrier)
  t0 = now
  32.times do |i|
    semaphore.async do
      in_flight += 1
      peak = [peak, in_flight].max
      sleep 0.25
      in_flight -= 1
    end
  end
  barrier.wait
  puts "  expected ceil(32/8) * 0.25 = 1.0s; measured #{(now - t0).round(2)}s, peak in flight #{peak}"
end

puts "\n== C: with_timeout =="
Sync do |task|
  t0 = now
  begin
    task.with_timeout(0.3) { sleep 5; "never returned" }
  rescue Async::TimeoutError => e
    puts "  #{e.class} after #{(now - t0).round(2)}s (deadline was 0.3s)"
  end
end

puts "\n== D: stop propagation and ensure =="
Sync do |task|
  events = []
  parent = task.async do
    2.times do |i|
      Async do |child|
        child.async do
          sleep 10
        ensure
          events << "grandchild-#{i} ensure"
        end
        sleep 10
      ensure
        events << "child-#{i} ensure"
      end
    end
    sleep 10
  ensure
    events << "parent ensure"
  end

  sleep 0.1              # let the tree get parked in sleeps
  t0 = now
  parent.stop
  puts "  stop returned in #{((now - t0) * 1000).round(1)}ms"
  sleep 0.1   # deferred cancels for the second subtree finish on the next loop pass
  puts "  ensure order: #{events.inspect}"
  puts "  parent stopped? #{parent.stopped?}"
end

puts "\n== D2: ensure runs when stopped mid-socket-read =="
require "socket"
Sync do |task|
  r, w = UNIXSocket.pair
  state = nil
  reader = task.async do
    r.gets                # parks in io_wait; no data ever comes
    state = :read
  ensure
    state = :ensure_ran
    r.close               # cleanup still possible: socket is intact here
  end
  sleep 0.05
  reader.stop
  puts "  reader stopped while parked in read; state=#{state.inspect}, socket closed=#{r.closed?}"
  w.close
end

puts "\n== E: error propagation through a barrier =="
Sync do
  finished = []
  barrier = Async::Barrier.new
  3.times do |i|
    barrier.async do
      raise "tool #{i} exploded" if i == 1
      sleep 5
      finished << i
    end
  end
  begin
    barrier.wait
  rescue => e
    puts "  barrier.wait raised: #{e.message.inspect}"
  ensure
    barrier.stop          # cancel the surviving siblings
  end
  puts "  siblings that completed: #{finished.inspect} (stopped before their 5s sleep ended)"
end
