# Chapter 2: prove that unmodified Net::HTTP and raw TCPSocket park the fiber.
# A thread-based HTTP server in this process answers after 300ms. Ten plain
# Net::HTTP requests run inside one reactor; if they parked, total wall time
# is ~0.3s, not 3.0s. A heartbeat task prints ticks to show the reactor is
# alive while the requests wait.

require "async"
require "net/http"
require "socket"

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}"

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

server = TCPServer.new("127.0.0.1", 0)
port = server.addr[1]

Thread.new do
  loop do
    conn = server.accept
    Thread.new(conn) do |c|
      c.readpartial(4096)
      sleep 0.3
      body = "ok"
      c.write "HTTP/1.1 200 OK\r\nContent-Length: #{body.size}\r\nConnection: close\r\n\r\n#{body}"
      c.close
    rescue IOError, Errno::ECONNRESET
    end
  end
end

t0 = now
ticks = []

Sync do |task|
  heartbeat = task.async do
    loop do
      sleep 0.1
      ticks << (now - t0).round(2)
    end
  end

  requests = 10.times.map do |i|
    task.async do
      res = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/req#{i}"))
      res.code
    end
  end
  codes = requests.map(&:wait)
  puts "10 x Net::HTTP (server latency 0.3s): #{(now - t0).round(2)}s total, codes #{codes.tally}"

  t1 = now
  sockets = 10.times.map do |i|
    task.async do
      s = TCPSocket.new("127.0.0.1", port)
      s.write "GET /raw#{i} HTTP/1.1\r\nHost: x\r\n\r\n"
      data = s.read
      s.close
      data.bytesize
    end
  end
  sizes = sockets.map(&:wait)
  puts "10 x raw TCPSocket read:               #{(now - t1).round(2)}s total, #{sizes.sum} bytes"

  heartbeat.stop
end

puts "heartbeat ticks while requests were in flight: #{ticks.inspect}"
