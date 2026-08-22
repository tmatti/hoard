# 03: The GVL demo — CPU-bound work on threads vs ractors.
# Threads in CRuby share one Global VM Lock: only one thread runs Ruby code
# at a time. Ractors each get their own lock, so they run truly in parallel.
Warning[:experimental] = false

def fib(n) = n < 2 ? n : fib(n - 1) + fib(n - 2)

N    = 4       # parallel units of work
WORK = 30      # fib(30) each

def bench(label)
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  dt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  puts format("%-12s %6.2fs", label, dt)
  dt
end

puts "#{N}x fib(#{WORK}) on #{Etc.nprocessors rescue '?'} cores" rescue nil
require 'etc'
puts "cores available: #{Etc.nprocessors}"

serial = bench("serial") do
  N.times { fib(WORK) }
end

threads = bench("threads") do
  Array.new(N) { Thread.new { fib(WORK) } }.each(&:join)
end

ractors = bench("ractors") do
  # Code (method definitions) is shared between ractors — only DATA is isolated.
  # So the ractor can call top-level fib() directly.
  Array.new(N) { Ractor.new(WORK) { |w| fib(w) } }.each(&:take)
end

puts
puts format("threads vs serial: %.2fx", serial / threads)
puts format("ractors vs serial: %.2fx", serial / ractors)
