# 02: Shareability — copy vs move vs shared references across the boundary.
Warning[:experimental] = false

# --- What is shareable as-is? ---
candidates = {
  "Integer"            => 42,
  "Symbol"             => :tool_call,
  "frozen String"      => "gpt".freeze,
  "mutable String"     => String.new("mutable"),
  "frozen Array of frozen" => [1, :a, "x".freeze].freeze,
  "frozen Array w/ mutable elem" => [String.new("m")].freeze,
  "Hash (mutable)"     => { role: "user" },
  "Class"              => Struct,
  "Module"             => Enumerable,
  # NB: Ractor.make_shareable(->(x){ x+1 }) at top level raises
  # "Proc's self is not shareable" because self is `main`. Build the lambda
  # where self IS shareable (here: the Integer class object) and it works.
  "Proc (isolated)"    => Ractor.make_shareable(Integer.instance_exec { ->(x) { x + 1 } }),
}
candidates.each do |name, obj|
  puts format("%-30s shareable? %s", name, Ractor.shareable?(obj))
end

# --- Copy semantics: send duplicates the object graph ---
msg = { messages: [{ role: "user", content: String.new("hi") }] }
worker = Ractor.new do
  m = Ractor.receive
  Ractor.yield(m.object_id) # object identity inside the worker
end
worker.send(msg)
inner_id = worker.take
puts "copy: same object? #{inner_id == msg.object_id} (deep-copied on send)"

# --- Move semantics: zero-copy transfer, sender loses access ---
big = "x" * 10_000_000 # ~10MB string
mover = Ractor.new do
  s = Ractor.receive
  Ractor.yield(s.bytesize)
end
mover.send(big, move: true)
puts "move: receiver sees #{mover.take} bytes"
begin
  big.bytesize
rescue => err
  puts "move: sender access now raises #{err.class}"
end

# --- Ractor.make_shareable deep-freezes ---
config = { model: "claude-sonnet-5", max_tokens: 1024, tools: ["search", "code"] }
Ractor.make_shareable(config)
puts "make_shareable: config frozen? #{config.frozen?}, nested frozen? #{config[:tools][0].frozen?}"

# Shareable objects are passed by reference (no copy): prove via object identity.
FROZEN_CONFIG = config
reader = Ractor.new(FROZEN_CONFIG) do |c|
  Ractor.yield(c.object_id)
end
puts "shared: same object across ractors? #{reader.take == FROZEN_CONFIG.object_id}"
