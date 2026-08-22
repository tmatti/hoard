# frozen_string_literal: true
# 01: Ractor basics on Ruby 4. Spawn, ports, value/join, isolation errors.
# Ruby 4.0 removed Ractor#take and Ractor.yield. Results come back through
# Ractor#value (shaped like Thread#value) and Ractor::Port.
Warning[:experimental] = false
STDOUT.sync = true

# A ractor is an isolated interpreter in your process. The block's last
# expression is its result; #value waits for it.
r = Ractor.new(21) { |n| n * 2 }
puts "value: #{r.value}"

# A port is a queue with one designated receiver: the ractor that created it.
# Any ractor may push into it. This is how a worker streams progress out.
port = Ractor::Port.new
w = Ractor.new(port) do |out|
  out << "progress: turn 1"
  out << "progress: turn 2"
  :done
end
puts port.receive
puts port.receive
puts "worker result: #{w.value}"

# Request/reply. Requests arrive on the default inbox (send/receive, which
# Ruby 4 kept); the caller ships a reply port along with the arguments.
calc = Ractor.new do
  loop do
    op, a, b, reply = Ractor.receive
    break if op == :stop
    reply << (op == :add ? a + b : a * b)
  end
end
reply = Ractor::Port.new
calc.send([:mul, 6, 7, reply])
puts "6 * 7 = #{reply.receive}"
calc.send([:stop, nil, nil, nil])

# Isolation is unchanged: the block may not capture ANY outer local.
x = 10
begin
  Ractor.new { x + 1 }
rescue ArgumentError => e
  puts "captured-var error: #{e.message.lines.first.strip}"
end

# Globals are main-ractor property.
$counter = 0
r2 = Ractor.new do
  $counter += 1
rescue => err
  "global-var error: #{err.class}: #{err.message}"
end
puts r2.value

# A crashed ractor raises Ractor::RemoteError in whoever waits on it,
# with the original exception in #cause.
boom = Ractor.new { raise "agent crashed" }
begin
  boom.value
rescue Ractor::RemoteError => e
  puts "remote error: #{e.cause.class}: #{e.cause.message}"
end

puts "Ractor#take still exists? #{Ractor.method_defined?(:take)}"
