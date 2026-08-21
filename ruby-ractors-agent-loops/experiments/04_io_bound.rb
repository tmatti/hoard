# 04: I/O-bound work — the case that actually dominates agent loops.
# An agent turn is ~99% waiting on the LLM API. CRuby threads RELEASE the GVL
# while blocked on I/O, so threads already give full concurrency for this.
# Simulate an LLM call with a real blocking read against a local TCP server
# that responds after 300ms.
Warning[:experimental] = false
require 'socket'

PORT = 43_210
server_thread = Thread.new do
  server = TCPServer.new('127.0.0.1', PORT)
  loop do
    client = server.accept
    Thread.new(client) do |c|
      c.gets           # read request line
      sleep 0.3        # model "thinking"
      c.puts '{"role":"assistant","content":"done"}'
      c.close
    end
  end
end
sleep 0.2 # let server boot

def llm_call(port)
  s = TCPSocket.new('127.0.0.1', port)
  s.puts "POST /v1/messages"
  resp = s.gets
  s.close
  resp
end

def bench(label)
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  puts format("%-9s %.2fs", label, Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0)
end

N = 8
bench("serial")  { N.times { llm_call(PORT) } }
bench("threads") { Array.new(N) { Thread.new { llm_call(PORT) } }.each(&:join) }
bench("ractors") { Array.new(N) { Ractor.new(PORT) { |p| llm_call(p) } }.each(&:take) }
