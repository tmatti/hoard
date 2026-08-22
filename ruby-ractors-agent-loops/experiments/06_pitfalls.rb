# frozen_string_literal: true
# 06: Production pitfalls — what breaks when real-world code runs in a ractor.
Warning[:experimental] = false
require 'socket'
require 'json' # required in MAIN ractor, up front — that's the pattern

# Tiny local HTTP server so net/http has something real to hit.
PORT = 43_211
Thread.new do
  server = TCPServer.new('127.0.0.1', PORT)
  loop do
    c = server.accept
    Thread.new(c) do |cl|
      req = +""
      while (line = cl.gets) && line != "\r\n"; req << line; end
      body = '{"ok":true}'
      cl.write "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
      cl.close
    end
  end
end
sleep 0.2


# 1. require INSIDE a non-main ractor
r = Ractor.new do
  require 'net/http'
  "require net/http inside ractor: OK"
rescue => e
  "require inside ractor: #{e.class}: #{e.message[0, 80]}"
end
puts r.take

# 2. net/http (required in main first) used FROM a ractor
require 'net/http'
r = Ractor.new(PORT) do |port|
  res = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/pusher/events"))
  "net/http from ractor: HTTP #{res.code} body=#{res.body}"
rescue => e
  "net/http from ractor: #{e.class}: #{e.message[0, 80]}"
end
puts r.take

# 3. JSON round-trip inside a ractor
r = Ractor.new do
  JSON.parse(JSON.generate({ "event" => "agent.completed", "turns" => 3 })).inspect
rescue => e
  "JSON in ractor: #{e.class}: #{e.message[0, 80]}"
end
puts "JSON in ractor: #{r.take}"

# 4. Class-level mutable state (the classic Rails-y memoization pattern)
class AgentConfig
  def self.settings
    @settings ||= { "model" => "claude-sonnet-5" } # lazy memo — mutable ivar on class
  end
end
r = Ractor.new do
  AgentConfig.settings["model"]
rescue => e
  "class ivar memo: #{e.class}: #{e.message[0, 80]}"
end
puts r.take

# 4b. ...and the fix: eagerly build + make_shareable before spawning
class AgentConfig2
  SETTINGS = Ractor.make_shareable({ "model" => "claude-sonnet-5" })
end
r = Ractor.new { "shareable const: #{AgentConfig2::SETTINGS["model"]} OK" }
puts r.take

# 5. ENV reads
r = Ractor.new do
  "ENV read: PATH starts with #{ENV['PATH'].to_s[0, 12].inspect} OK"
rescue => e
  "ENV read: #{e.class}: #{e.message[0, 60]}"
end
puts r.take

# 6. Time/random/SecureRandom
require 'securerandom'
r = Ractor.new do
  "Time.now=#{Time.now.utc.strftime('%H:%M')} rand=#{rand(100)} uuid=#{SecureRandom.uuid[0, 8]} OK"
rescue => e
  "time/random: #{e.class}: #{e.message[0, 60]}"
end
puts r.take
