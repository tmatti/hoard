# frozen_string_literal: true
# 05: Agent loops on ractors, Ruby 4 port topology.
#
#   main (supervisor)
#     creates ready_port    workers announce themselves when idle
#             results_port  workers push finished runs
#             events_port   workers stream progress (the Pusher seam)
#
# A port's receive side belongs to the ractor that created it, so all three
# ports are received in main. Job dispatch is pull-based: an idle worker
# pushes itself into ready_port, the supervisor sends it a job on its inbox.
# One Ractor.select watches all three ports at once.
Warning[:experimental] = false
STDOUT.sync = true

# Tools live in a module. Modules are shareable and this is the shape a real
# tool registry has. (A top-level lambda captures `main` as self and cannot
# be shared; Ractor.shareable_proc exists if you need a closure.)
module Tools
  module_function
  def search(args)    = "3 results for #{args["q"].inspect}: [ractors, ports, gvl]"
  def calculate(args) = eval(args["expr"]).to_s # demo only!
end
TOOL_NAMES = %w[search calculate].freeze

SYSTEM_PROMPT = "You are a research agent. Use tools, then answer."

# Deterministic fake LLM: search on turn 1, calculate on turn 2, then answer.
# sleep stands in for network and inference latency.
def fake_llm(messages)
  sleep(0.05 + messages.size * 0.01)
  case messages.count { |m| m[:role] == :assistant }
  when 0 then { role: :assistant, tool_call: { name: "search",    args: { "q" => "ractor agent loops" } } }
  when 1 then { role: :assistant, tool_call: { name: "calculate", args: { "expr" => "6 * 7" } } }
  else        { role: :assistant, content: "Answer: ractors give parallel agent loops; 6*7=42." }
  end
end

# The agent loop. Ordinary Ruby; the only ractor-aware part is pushing small
# frozen event hashes into the events port.
def run_agent(job, events)
  agent_id = job[:agent_id]
  messages = [{ role: :system, content: SYSTEM_PROMPT }, { role: :user, content: job[:prompt] }]
  events << { agent_id:, type: "agent.started" }
  turn = 0
  loop do
    turn += 1
    response = fake_llm(messages)
    messages << response
    if (tc = response[:tool_call])
      events << { agent_id:, type: "tool.called", tool: tc[:name] }
      raise "unknown tool #{tc[:name]}" unless TOOL_NAMES.include?(tc[:name])
      result = Tools.public_send(tc[:name], tc[:args])
      messages << { role: :tool, name: tc[:name], content: result }
      events << { agent_id:, type: "tool.result", tool: tc[:name], preview: result[0, 40] }
    else
      events << { agent_id:, type: "agent.completed", turns: turn }
      return { agent_id:, turns: turn, answer: response[:content], messages: messages.size }
    end
  end
end

POOL_SIZE = 4
JOBS      = 8

ready_port   = Ractor::Port.new
results_port = Ractor::Port.new
events_port  = Ractor::Port.new

workers = POOL_SIZE.times.map do |i|
  Ractor.new(ready_port, results_port, events_port, name: "worker-#{i}") do |ready, results, events|
    loop do
      ready << Ractor.current          # announce: idle, send me work
      job = Ractor.receive
      break if job == :shutdown
      results << run_agent(job, events)
    end
    :stopped
  end
end

jobs = JOBS.times.map { |i| { agent_id: "agent-#{i}", prompt: "Research ractors, then compute 6*7" } }

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
results, events = [], []
EXPECTED_EVENTS = JOBS * 6 # started + 2 tool.called + 2 tool.result + completed
until results.size == JOBS && events.size == EXPECTED_EVENTS
  port, msg = Ractor.select(ready_port, results_port, events_port)
  case port
  when ready_port   then msg.send(jobs.shift || :shutdown)  # msg is an idle worker
  when results_port then results << msg
  when events_port  then events << msg
    # production: hand msg to the Pusher publisher thread here
  end
end
dt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

# Drain remaining ready announcements so every worker gets its :shutdown.
workers.each { |w| w.send(:shutdown) rescue nil }
workers.each { |w| w.join rescue nil }

puts "#{JOBS} agents, #{POOL_SIZE} workers -> #{results.size} results in #{dt.round(2)}s"
puts "sample result: #{results.first.inspect}"
puts "events seen: #{events.size}; last: #{events.last.inspect}"
counts = events.group_by { _1[:type] }.transform_values(&:size)
puts "event counts: #{counts.inspect}"
