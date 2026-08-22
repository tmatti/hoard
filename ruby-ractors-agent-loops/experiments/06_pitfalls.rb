# frozen_string_literal: true
# 06: What breaks when real-world code runs inside a ractor on Ruby 4,
# and what works. Every claim in the report traces to a line here.
Warning[:experimental] = false
STDOUT.sync = true
require 'socket'
require 'json' # required in the MAIN ractor, up front. That is the pattern.

puts RUBY_VERSION

# A local HTTP server so net/http has something real to hit.
PORT = 43_211
Thread.new do
  server = TCPServer.new('127.0.0.1', PORT)
  loop do
    c = server.accept
    Thread.new(c) do |cl|
      while (line = cl.gets) && line != "\r\n"; end
      body = '{"ok":true}'
      cl.write "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
      cl.close
    end
  end
end
sleep 0.2

# 1. require inside a non-main ractor (Ruby 4 delegates it to main).
r = Ractor.new do
  require 'csv'
  "require 'csv' inside ractor: OK"
rescue => e
  "require inside ractor: #{e.class}: #{e.message[0, 80]}"
end
puts r.value

# 2. net/http used from inside a ractor.
require 'net/http'
r = Ractor.new(PORT) do |port|
  res = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/pusher/events"))
  "net/http from ractor: HTTP #{res.code} body=#{res.body}"
rescue => e
  "net/http from ractor: #{e.class}: #{e.message[0, 80]}"
end
puts r.value

# 3. The pusher gem (2.1.1, httpclient-based) from inside a ractor.
begin
  require 'pusher'
  r = Ractor.new do
    client = Pusher::Client.new(app_id: "1", key: "k", secret: "s", cluster: "us2")
    client.trigger("ch", "ev", { a: 1 })
    "pusher trigger in ractor: unexpectedly succeeded"
  rescue => e
    "pusher trigger in ractor: #{e.class}: #{e.message[0, 80]}"
  end
  puts r.value
rescue LoadError
  puts "pusher gem not installed for this ruby; skipped"
end

# 4. JSON round-trip inside a ractor.
r = Ractor.new do
  JSON.parse(JSON.generate({ "event" => "agent.completed", "turns" => 3 })).inspect
rescue => e
  "JSON in ractor: #{e.class}: #{e.message[0, 80]}"
end
puts "JSON in ractor: #{r.value}"

# 5. Class-level lazy memoization, the classic Rails idiom.
class AgentConfig
  def self.settings
    @settings ||= { "model" => "claude-sonnet-5" }
  end
end
r = Ractor.new do
  AgentConfig.settings["model"]
rescue => e
  "class ivar memo: #{e.class}: #{e.message[0, 80]}"
end
puts r.value

# 5b. The fix: build eagerly at boot, deep-freeze, expose as a constant.
class AgentConfig2
  SETTINGS = Ractor.make_shareable({ "model" => "claude-sonnet-5" })
end
r = Ractor.new { "shareable const: #{AgentConfig2::SETTINGS["model"]} OK" }
puts r.value

# 6. ENV, time, randomness.
require 'securerandom'
r = Ractor.new do
  "ENV/time/random: PATH=#{ENV['PATH'].to_s[0, 12].inspect} " \
    "#{Time.now.utc.strftime('%H:%M')} rand=#{rand(100)} uuid=#{SecureRandom.uuid[0, 8]} OK"
rescue => e
  "ENV/time/random: #{e.class}: #{e.message[0, 60]}"
end
puts r.value

# 7. Timeout.timeout inside a ractor (thread-based; expect failure).
require 'timeout'
r = Ractor.new do
  Timeout.timeout(1) { "Timeout in ractor: OK" }
rescue => e
  "Timeout in ractor: #{e.class}: #{e.message[0, 80]}"
end
puts r.value
