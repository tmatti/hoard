# frozen_string_literal: true
# 03: CPU-bound work four ways: serial, threads, ractors, forked processes.
# Threads share one GVL, so they add nothing for computation. Each ractor has
# its own lock and runs on its own core. Forks are the hardware ground truth.
Warning[:experimental] = false
STDOUT.sync = true
require 'etc'

def fib(n) = n < 2 ? n : fib(n - 1) + fib(n - 2)

N    = Etc.nprocessors
WORK = 32

def bench(label)
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  dt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  puts format("%-9s %6.2fs", label, dt)
  dt
end

puts "#{RUBY_VERSION}: #{N}x fib(#{WORK}) on #{N} cores"

serial = bench("serial") { N.times { fib(WORK) } }

threads = bench("threads") do
  Array.new(N) { Thread.new { fib(WORK) } }.each(&:join)
end

ractors = bench("ractors") do
  # Method definitions are shared code; only data is isolated. The ractor
  # can call top-level fib directly.
  Array.new(N) { Ractor.new(WORK) { |w| fib(w) } }.each(&:value)
end

forks = bench("forks") do
  Array.new(N) { fork { fib(WORK) } }.each { Process.wait(_1) }
end

puts
puts format("threads: %.2fx  ractors: %.2fx  forks: %.2fx (vs serial)",
            serial / threads, serial / ractors, serial / forks)
