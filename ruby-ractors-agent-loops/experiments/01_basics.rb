# 01: Ractor basics — spawn, send/receive, take, and isolation.
# Ruby 3.3 API. (3.5 replaces take/yield with Ractor::Port — noted in report.)

Warning[:experimental] = false

# A ractor is created with a block. The block runs in parallel, in its own
# isolated heap. Arguments must be shareable or are copied.
r = Ractor.new(21) do |n|
  n * 2 # last expression is the ractor's "return value", fetched with #take
end
puts "take: #{r.take.inspect}"

# Message passing: push style (send -> receive)
echo = Ractor.new do
  loop do
    msg = Ractor.receive        # blocks until a message arrives (infinite inbox)
    break if msg == :stop
    Ractor.yield("echo: #{msg}") # blocks until someone takes
  end
end
echo.send("hello")
puts echo.take
echo.send(:stop)

# Isolation: the block cannot capture outer local variables...
x = 10
begin
  Ractor.new { x + 1 }
rescue => e
  puts "captured-var error: #{e.class}: #{e.message.lines.first.strip}"
end

# ...and cannot touch non-shareable globals/objects from other ractors.
$counter = 0
# (note: `rescue => err` — even the rescue variable must not collide with an
#  outer local, or Ractor.new refuses the block as non-isolable!)
r2 = Ractor.new do
  $counter += 1
rescue => err
  "global-var error: #{err.class}: #{err.message}"
end
puts r2.take

# Unhandled exceptions inside a ractor surface on #take as Ractor::RemoteError
boom = Ractor.new { raise "agent crashed" }
begin
  boom.take
rescue Ractor::RemoteError => e
  puts "remote error: #{e.cause.class}: #{e.cause.message}"
end
