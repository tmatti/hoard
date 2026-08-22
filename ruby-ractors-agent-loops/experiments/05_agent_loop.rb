# frozen_string_literal: true
#
# ^ NOT optional decoration. Without it, TOOL_NAMES = %w[...].freeze is a
# frozen array of MUTABLE strings -> not shareable -> every worker ractor
# dies with Ractor::IsolationError at first access, and the supervisor hangs
# in Ractor.select. (Happened for real; see notes.md.)
#
# 05: Agent loops on ractors — supervisor + worker pool + event-bus ractor.
#
# Topology (Ruby 3.3 idioms; see report for the 3.5 Ractor::Port version):
#
#   main (supervisor)
#     ├── pipe ractor      — job queue; workers pull from it => load balancing
#     ├── worker ractors   — each runs the agent loop (LLM turn -> tool -> repeat)
#     └── bus ractor       — receives events from workers; in production this
#                            ractor owns the Pusher HTTP client and batches
#                            trigger() calls. Here it collects + timestamps.
#
# Ractor objects are themselves SHAREABLE, so workers can hold a reference to
# the bus ractor and .send() events to it — the one sanctioned form of "shared
# access": funnel all effects through one owner.
Warning[:experimental] = false

# ---- The home-rolled-framework-ish bits (all shareable constants) ----------
# Tools as a module, not top-level lambdas: top-level lambdas capture `main`
# as self and can't be made shareable (hit this again — see notes.md).
# Modules are shareable by nature, and this matches real framework shape.
module Tools
  module_function
  def search(args)    = "3 results for #{args["q"].inspect}: [ractors, ports, gvl]"
  def calculate(args) = eval(args["expr"]).to_s # demo only!
end
TOOL_NAMES = %w[search calculate].freeze

SYSTEM_PROMPT = "You are a research agent. Use tools, then answer.".freeze

# Deterministic fake LLM: turn 1 -> search, turn 2 -> calculate, turn 3 -> final.
# Simulates network+inference latency with sleep (GVL-irrelevant inside a ractor).
def fake_llm(messages)
  sleep(0.05 + messages.size * 0.01)
  case messages.count { |m| m[:role] == :assistant }
  when 0 then { role: :assistant, tool_call: { name: "search",    args: { "q" => "ractor agent loops" } } }
  when 1 then { role: :assistant, tool_call: { name: "calculate", args: { "expr" => "6 * 7" } } }
  else        { role: :assistant, content: "Answer: ractors give parallel agent loops; 6*7=42." }
  end
end

# ---- The agent loop itself (runs inside a worker ractor) -------------------
def run_agent(job, bus)
  agent_id = job[:agent_id]
  messages = [{ role: :system, content: SYSTEM_PROMPT }, { role: :user, content: job[:prompt] }]
  bus.send({ agent_id:, type: "agent.started" })
  turn = 0
  loop do
    turn += 1
    response = fake_llm(messages)
    messages << response
    if (tc = response[:tool_call])
      bus.send({ agent_id:, type: "tool.called", tool: tc[:name] })
      raise "unknown tool #{tc[:name]}" unless TOOL_NAMES.include?(tc[:name])
      result = Tools.public_send(tc[:name], tc[:args])
      messages << { role: :tool, name: tc[:name], content: result }
      bus.send({ agent_id:, type: "tool.result", tool: tc[:name], preview: result[0, 40] })
    else
      bus.send({ agent_id:, type: "agent.completed", turns: turn })
      return { agent_id:, turns: turn, answer: response[:content], messages: messages.size }
    end
  end
end

# ---- Wiring ----------------------------------------------------------------
POOL_SIZE = 4
JOBS      = 8

# Event bus: single owner of the "Pusher client". Everything funnels here.
bus = Ractor.new do
  events = []
  loop do
    ev = Ractor.receive
    break if ev == :drain
    events << ev.merge(t: Process.clock_gettime(Process::CLOCK_MONOTONIC))
    # production: batch into Pusher.trigger_batch every N events / M ms
  end
  Ractor.yield(events)
end

# Job queue: the classic "pipe" — many workers .take from it, giving pull-based
# load balancing with zero extra code.
pipe = Ractor.new do
  loop { Ractor.yield(Ractor.receive) }
end

workers = POOL_SIZE.times.map do |i|
  Ractor.new(pipe, bus, name: "worker-#{i}") do |pipe, bus|
    loop do
      job = pipe.take
      break if job == :shutdown
      Ractor.yield(run_agent(job, bus))
    end
  end
end

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
JOBS.times { |i| pipe.send({ agent_id: "agent-#{i}", prompt: "Research ractors, then compute 6*7" }) }

results = []
while results.size < JOBS
  _r, result = Ractor.select(*workers)
  results << result
end
dt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

POOL_SIZE.times { pipe.send(:shutdown) }
bus.send(:drain)
events = bus.take

puts "#{JOBS} agents, #{POOL_SIZE} workers -> #{results.size} results in #{dt.round(2)}s"
puts "sample result: #{results.first.inspect}"
puts "bus captured #{events.size} events; last: #{events.last.reject { |k,_| k == :t }.inspect}"
counts = events.group_by { _1[:type] }.transform_values(&:size)
puts "event counts: #{counts.inspect}"
serial_estimate = JOBS * (0.05*3 + (2+3+4+5+6)*0.01) # rough
puts "(each agent = 3 LLM turns; serial would be ~#{serial_estimate.round(1)}s+)"
