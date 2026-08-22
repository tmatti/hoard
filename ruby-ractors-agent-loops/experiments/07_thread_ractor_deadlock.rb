# frozen_string_literal: true
# 07: The Sidekiq-shaped landmine. Sidekiq runs jobs on a thread pool; Puma
# serves requests on one. "Each job spawns a ractor and waits on it" means
# several threads blocking in Ractor#value at once. Test whether that still
# wedges the process on this Ruby, with a watchdog so the script always exits.
#
# History: on the Ruby 4.0 preview (and 3.x with #take) this deadlocked the
# whole process and the process ignored SIGTERM. Upstream: bugs #17826, #21037.
Warning[:experimental] = false
STDOUT.sync = true

puts "ruby #{RUBY_VERSION}"

v = Thread.new { Ractor.new { 42 }.value }.value
puts "single thread -> ractor -> value: #{v} (OK)"

threads = Array.new(3) { |i| Thread.new(i) { |n| Ractor.new(n) { |x| x * 10 }.value } }
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 8
done = false
until done || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  done = threads.none?(&:alive?)
  sleep 0.2
end
if done
  puts "3 concurrent threads -> ractors: #{threads.map(&:value).inspect} (no deadlock on this ruby)"
else
  alive = threads.count(&:alive?)
  puts "3 concurrent threads -> ractors: DEADLOCK (#{alive}/3 threads still blocked after 8s)"
  puts "=> never block multiple threads on ractor operations; use one owner thread"
  exit! 0 # regular exit would join the wedged threads and hang too
end

# Heavier version: more threads, more contention, results crossing back.
threads = Array.new(8) { |i| Thread.new(i) { |n| Ractor.new(n) { |x| sleep(0.01); x + 1 }.value } }
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
done = false
until done || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  done = threads.none?(&:alive?)
  sleep 0.2
end
if done
  puts "8 concurrent threads -> ractors: #{threads.map(&:value).inspect} (no deadlock)"
else
  puts "8 concurrent threads -> ractors: DEADLOCK (#{threads.count(&:alive?)}/8 blocked after 10s)"
  exit! 0
end
