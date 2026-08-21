# frozen_string_literal: true
# 07: The Sidekiq/Puma landmine — concurrent Thread -> Ractor waits deadlock.
#
# Sidekiq runs jobs on a pool of threads; Puma serves requests on threads.
# The obvious pattern "each job spawns a ractor and waits for its result"
# WEDGES THE WHOLE PROCESS once several threads do it at the same time
# (and the wedged process ignores SIGTERM — kill -9 territory).
#
# Known upstream: Bug #17826 "Ractor#take hangs if used in multiple Threads",
# Bug #21037 "Ractors hang with multiple threads" — the waiting machinery has
# a literal "TODO: make multithreaded". Reproduced on 3.3.6, 3.4.5 and the
# 4.0 preview (ruby 3.5.0preview1 build).
#
# This file demonstrates it with a watchdog so it exits instead of hanging CI.
Warning[:experimental] = false
STDOUT.sync = true # exit! skips buffer flush; sync or lose all output to a pipe

puts "ruby #{RUBY_VERSION}"

# One thread doing spawn+wait: perfectly fine.
v = Thread.new { Ractor.new { 42 }.take }.value
puts "single thread -> ractor -> take: #{v} (OK)"

# Several threads doing it concurrently: deadlock.
threads = Array.new(3) { |i| Thread.new(i) { |n| Ractor.new(n) { |x| x * 10 }.take } }
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 8
done = false
until done || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  done = threads.none?(&:alive?)
  sleep 0.2
end
if done
  puts "3 concurrent threads -> ractors: #{threads.map(&:value).inspect} (fixed in this ruby!)"
else
  alive = threads.count(&:alive?)
  puts "3 concurrent threads -> ractors: DEADLOCK (#{alive}/3 threads still blocked after 8s)"
  puts "=> never block multiple threads on ractor operations; use one owner thread"
  exit! 0 # exit! — regular exit would join the wedged threads and hang too
end
