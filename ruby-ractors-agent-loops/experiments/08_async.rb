# frozen_string_literal: true
# 08: Async Ruby (the async gem, a Fiber::Scheduler implementation) as the
# I/O layer for agent loops, and how it composes with ractors.
#
# Fibers give I/O concurrency like threads do, but a task costs kilobytes
# instead of a native thread, and you can run thousands in one thread.
# No CPU parallelism: everything runs on one core. That is ractors' job.
Warning[:experimental] = false
STDOUT.sync = true
require 'socket'
require 'async'
require 'async/semaphore'
require 'async/barrier'

puts "#{RUBY_VERSION}, async #{Async::VERSION}"

PORT = 43_212
Thread.new do
  server = TCPServer.new('127.0.0.1', PORT)
  loop do
    c = server.accept
    Thread.new(c) { |cl| cl.gets; sleep 0.3; cl.puts "ok"; cl.close }
  end
end
sleep 0.2

def llm_call(port)
  s = TCPSocket.new('127.0.0.1', port)
  s.puts "POST /v1/messages"
  resp = s.gets
  s.close
  resp
end

def bench(label)
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  puts format("%-28s %.2fs", label, Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0)
end

# A. 50 concurrent calls: 50 threads vs 50 fiber tasks in ONE thread.
N = 50
bench("#{N} calls, threads") do
  Array.new(N) { Thread.new { llm_call(PORT) } }.each(&:join)
end
bench("#{N} calls, async tasks") do
  Async do |task|
    N.times.map { task.async { llm_call(PORT) } }.each(&:wait)
  end
end

# B. Structured concurrency: a barrier owns the tasks, a semaphore caps how
# many run at once. This is the shape of "fan out 32 tool calls, at most 8
# in flight", which no thread pool gives you this directly.
bench("32 calls, semaphore cap 8") do
  Async do
    barrier   = Async::Barrier.new
    semaphore = Async::Semaphore.new(8, parent: barrier)
    32.times { semaphore.async { llm_call(PORT) } }
    barrier.wait
  end
end

# C. Does async run INSIDE a ractor?
r = Ractor.new(PORT) do |port|
  require 'async'
  Async do |task|
    3.times.map { task.async { llm_call(port) } }.each(&:wait)
  end
  "async inside ractor: OK (3 concurrent calls)"
rescue => e
  "async inside ractor: #{e.class}: #{e.message[0, 70]}"
end
puts r.value

# D. The hybrid question: does waiting on a ractor block the whole reactor?
# Ractor#value and Port#receive are not scheduler-aware. While one task waits
# on a ractor, every other fiber in that thread stops too. Measure it.
bench("ractor wait inside async") do
  Async do |task|
    a = task.async { Ractor.new { sleep 0.5; :cpu_done }.value } # blocks the thread
    b = task.async { llm_call(PORT) }                            # should overlap, can't
    [a, b].each(&:wait)
  end
end
puts "  (0.8s = the 0.5s ractor wait blocked the 0.3s I/O call; no overlap)"

# E. The bridge that works: one owner THREAD runs the ractor pool; async code
# talks to it through Thread::Queue, whose #pop parks the fiber, not the
# thread. I/O keeps flowing while the CPU work runs in parallel.
inbox = Queue.new
owner = Thread.new do
  pool_port = Ractor::Port.new
  loop do
    payload, reply = inbox.pop
    break if payload == :stop
    Ractor.new(pool_port, payload) { |out, n| out << [n, n * 2] } # stand-in CPU work
    reply << pool_port.receive
  end
end

bench("owner-thread bridge") do
  Async do |task|
    a = task.async do
      reply = Queue.new
      inbox << [21, reply]
      reply.pop # fiber parks here; the reactor keeps running
    end
    b = task.async { llm_call(PORT) }
    puts "  cpu result via bridge: #{a.wait.inspect}"
    b.wait
  end
end
inbox << [:stop, nil]
owner.join
puts "  (0.3s: the I/O call and the ractor work overlapped)"
