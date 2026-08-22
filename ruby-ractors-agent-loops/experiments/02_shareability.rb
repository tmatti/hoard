# frozen_string_literal: true
# 02: Shareability on Ruby 4. Copy vs move vs shared references.
Warning[:experimental] = false
STDOUT.sync = true

# What crosses the boundary as-is?
candidates = {
  "Integer"                      => 42,
  "Symbol"                       => :tool_call,
  "frozen String"                => "claude",
  "mutable String"               => String.new("mutable"),
  "frozen Array of frozen"       => [1, :a, "x"].freeze,
  "frozen Array w/ mutable elem" => [String.new("m")].freeze,
  "Hash (mutable)"               => { role: "user" },
  "Class"                        => Struct,
  "Module"                       => Enumerable,
  "shareable_proc"               => Ractor.shareable_proc { |x| x + 1 },
}
candidates.each do |name, obj|
  puts format("%-30s shareable? %s", name, Ractor.shareable?(obj))
end

# COPY (the default): send deep-copies the object graph.
out = Ractor::Port.new
msg = { messages: [{ role: "user", content: String.new("hi") }] }
worker = Ractor.new(out) do |port|
  m = Ractor.receive
  port << m.object_id
end
worker.send(msg)
puts "copy: same object? #{out.receive == msg.object_id} (deep-copied on send)"

# MOVE: zero-copy ownership transfer. The sender's reference dies.
big = String.new("x") * 10_000_000
mover = Ractor.new(out) do |port|
  s = Ractor.receive
  port << s.bytesize
end
mover.send(big, move: true)
puts "move: receiver sees #{out.receive} bytes"
begin
  big.bytesize
rescue => err
  puts "move: sender access now raises #{err.class}"
end

# SHARE: make_shareable deep-freezes in place; shareable objects cross by
# reference, proven by identical object_id on both sides.
config = { model: "claude-sonnet-5", max_tokens: 1024, tools: ["search", "code"] }
Ractor.make_shareable(config)
puts "make_shareable: config frozen? #{config.frozen?}, nested frozen? #{config[:tools][0].frozen?}"

FROZEN_CONFIG = config
reader = Ractor.new(out, FROZEN_CONFIG) { |port, c| port << c.object_id }
puts "shared: same object across ractors? #{reader.value; out.receive == FROZEN_CONFIG.object_id}"

# Ruby 4 fixed the old top-level-lambda wall directly. A plain lambda built at
# the top level captures `main` as self and cannot be shared; shareable_proc
# and shareable_lambda exist for exactly this.
begin
  Ractor.make_shareable(->(x) { x + 1 })
rescue => err
  puts "plain top-level lambda: #{err.class}: #{err.message[0, 50]}"
end
sp = Ractor.shareable_proc { |x| x * 10 }
runner = Ractor.new(out, sp) { |port, f| port << f.call(4) }
runner.join
puts "shareable_proc in another ractor: #{out.receive}"
