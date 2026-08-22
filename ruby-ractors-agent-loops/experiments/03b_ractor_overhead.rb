# 03b: Why were ractors slower than serial on fib(30)?
# Hypotheses: (a) spawn overhead, (b) multi-ractor mode de-optimizing the VM
# (inline/global caches become synchronized once >1 ractor has ever run),
# (c) workload too small.
Warning[:experimental] = false

def fib(n) = n < 2 ? n : fib(n - 1) + fib(n - 2)

def t = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# 1. Baseline in single-ractor mode (no ractor has been created yet)
t0 = t; fib(30); puts format("fib(30) main, single-ractor mode: %.3fs", t - t0)

# 2. Spawn cost of one trivial ractor
t0 = t; Ractor.new {}.take; puts format("spawn+join empty ractor:         %.3fs", t - t0)

# 3. ONE ractor doing fib(30) — no parallelism contention possible
t0 = t; Ractor.new { fib(30) }.take; puts format("fib(30) in one ractor:           %.3fs", t - t0)

# 4. Main ractor again — but now the VM is in multi-ractor mode forever
t0 = t; fib(30); puts format("fib(30) main, multi-ractor mode: %.3fs", t - t0)

# 5. And a bigger parallel run to see if scaling shows up at larger sizes
require 'etc'
n = Etc.nprocessors
t0 = t; n.times { fib(32) }; serial = t - t0
t0 = t; Array.new(n) { Ractor.new { fib(32) } }.each(&:take); par = t - t0
puts format("%dx fib(32) serial: %.2fs   ractors: %.2fs   speedup: %.2fx", n, serial, par, serial / par)
