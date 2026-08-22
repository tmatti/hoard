# Chapter 4: consuming an SSE stream with async-http.
# The fake server emits 20 token deltas at 30ms intervals. The client reads
# the response body chunk by chunk as it arrives, not after it completes.
# Then three streams run concurrently in one reactor to show interleaving.

require "async"
require "async/http/internet"
require "json"
require_relative "support"

puts "ruby #{RUBY_VERSION}, async #{Async::VERSION}"

# Minimal SSE reader: accumulate chunks, yield each complete `data: ...` event.
def each_sse_event(response)
  buffer = +""
  while (chunk = response.body.read)
    buffer << chunk
    while (event, rest = buffer.split("\n\n", 2); rest)
      buffer = rest
      payload = event[/^data: (.*)/, 1]
      yield payload if payload
    end
  end
end

with_fake_llm do |port|
  Sync do
    internet = Async::HTTP::Internet.new

    t0 = now
    arrivals = []
    internet.get("http://127.0.0.1:#{port}/v1/stream?tokens=20&interval=0.03") do |response|
      each_sse_event(response) do |data|
        arrivals << (now - t0).round(3)
        break if data == "[DONE]"
      end
    end
    puts "  single stream: 20 deltas + [DONE]"
    puts "  first delta at #{arrivals.first}s, last at #{arrivals.last}s (whole-body wait would be ~#{arrivals.last}s with zero output until then)"
    gaps = arrivals.each_cons(2).map { |a, b| b - a }
    puts format("  inter-arrival: mean %.1fms (server interval 30ms)", gaps.sum / gaps.size * 1000)

    # Three concurrent streams, one reactor: deltas interleave as they arrive.
    puts "\n  three concurrent streams, first 12 arrivals tagged by stream:"
    t0 = now
    order = []
    tasks = 3.times.map do |s|
      Async do
        internet.get("http://127.0.0.1:#{port}/v1/stream?tokens=6&interval=#{0.02 + s * 0.01}") do |response|
          each_sse_event(response) do |data|
            order << "s#{s}" unless data == "[DONE]"
          end
        end
      end
    end
    tasks.each(&:wait)
    puts "  #{order.first(12).join(" ")} ... (#{order.size} total in #{(now - t0).round(2)}s)"
  ensure
    internet&.close
  end
end
