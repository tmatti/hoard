# Chapter 1: fibers from first principles.
# Part A: Fiber.new / resume / yield, no scheduler, no gems.
# Part B: hand-scheduling fibers over real sockets, to show why nobody does this.
# Part C: Fiber.set_scheduler makes plain `sleep` cooperative.
# Part D: count which Fiber::Scheduler hooks fire for sleep, sockets, Queue#pop, DNS.

require "socket"

puts "ruby #{RUBY_VERSION}"

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

puts "\n== A: raw resume/yield =="

fiber = Fiber.new do |first|
  puts "  fiber started, got #{first.inspect}"
  second = Fiber.yield(first * 2)
  puts "  fiber resumed, got #{second.inspect}"
  :finished
end

puts "  resume(21) returned #{fiber.resume(21).inspect}"
puts "  resume(:go) returned #{fiber.resume(:go).inspect}"
puts "  alive? #{fiber.alive?}"

puts "\n== B: hand-scheduled I/O, the painful way =="

# Two fibers each read a line from a socket pair. The writer side delays.
# Without a scheduler, WE must run the event loop: IO.select, then resume
# whichever fiber's socket is readable. Fibers yield their socket back to us.

writers = []
readers = []
2.times do
  r, w = UNIXSocket.pair
  readers << r
  writers << w
end

Thread.new do
  sleep 0.3
  writers[1].puts "second socket data"
  sleep 0.3
  writers[0].puts "first socket data"
end

fibers = readers.map.with_index do |sock, i|
  Fiber.new do
    Fiber.yield(sock) until sock.wait_readable(0)   # park: hand the socket to the loop
    puts "  fiber #{i} read: #{sock.gets.strip.inspect} at t=#{(now - $t0).round(2)}s"
  end
end

$t0 = now
pending = fibers.map { |f| [f, f.resume] }.to_h     # fiber => socket it waits on
until pending.empty?
  ready, = IO.select(pending.values)
  pending.each do |f, sock|
    next unless ready.include?(sock)
    result = f.resume
    pending.delete(f) unless f.alive?
    pending[f] = result if f.alive?
  end
end
puts "  hand-rolled loop total: #{(now - $t0).round(2)}s (overlapped, but we wrote a scheduler)"

puts "\n== C: Fiber.set_scheduler, same sleep code, two behaviours =="

# Blocking: two fibers, each sleeps 0.5s. resume runs them to completion in turn.
t0 = now
2.times do |i|
  Fiber.new { sleep 0.5 }.resume
end
puts "  no scheduler:   2 x sleep(0.5) sequentially = #{(now - t0).round(2)}s"

# Scheduled: identical sleeps, but the thread has a Fiber::Scheduler.
# `sleep` is intercepted (kernel_sleep hook) and parks the fiber instead.
require "async"

t0 = now
Thread.new do
  Fiber.set_scheduler(Async::Scheduler.new)
  2.times { Fiber.schedule { sleep 0.5 } }
end.join
puts "  with scheduler: 2 x sleep(0.5) overlapped   = #{(now - t0).round(2)}s"

puts "\n== D: which hooks fire =="

# Wrap the interesting scheduler hooks with counters. Whatever CRuby routes
# through the scheduler shows up here; anything it doesn't, won't.
# Ruby 4 also calls io_close if the scheduler defines it, but Async::Scheduler
# 2.44.1 doesn't implement that hook yet, so only wrap what the superclass has.
class CountingScheduler < Async::Scheduler
  HOOKS = %i[kernel_sleep io_wait block unblock address_resolve fiber_interrupt io_close]
    .select { |hook| Async::Scheduler.method_defined?(hook) }

  def counts = @counts ||= Hash.new(0)

  HOOKS.each do |hook|
    define_method(hook) do |*args, **kwargs, &blk|
      counts[hook] += 1
      super(*args, **kwargs, &blk)
    end
  end
end

puts "  hooks async 2.44.1 implements of the ones we watch: #{CountingScheduler::HOOKS.inspect}"

scheduler = nil
server = TCPServer.new("127.0.0.1", 0)
port = server.addr[1]
Thread.new do
  client = server.accept
  sleep 0.05
  client.puts "hello"
  client.close
end

Thread.new do
  # The scheduler must be built on the thread that runs it; its selector binds
  # to the creating thread, and using it elsewhere raises FiberError.
  scheduler = CountingScheduler.new
  Fiber.set_scheduler(scheduler)

  Fiber.schedule { sleep 0.05 }                                # -> kernel_sleep

  Fiber.schedule do                                            # -> io_wait
    sock = TCPSocket.new("127.0.0.1", port)
    sock.gets
    sock.close
  end

  queue = Thread::Queue.new
  Fiber.schedule { queue.pop }                                 # -> block / unblock
  Fiber.schedule { sleep 0.02; queue << :item }

  Fiber.schedule { Addrinfo.getaddrinfo("localhost", 80) }     # -> address_resolve
end.join

scheduler.counts.sort.each { |hook, n| puts format("  %-16s fired %d time(s)", hook, n) }
