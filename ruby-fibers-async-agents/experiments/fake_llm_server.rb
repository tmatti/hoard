# A deterministic fake LLM API for the agent-loop experiments.
# Endpoints:
#   POST /v1/chat    body: {"run":id,"turn":n,"latency":s,"tools":k,"flaky_key":str}
#                    Sleeps `latency`, then answers with tool_calls while
#                    turn < 2, and a final message on turn >= 2.
#                    If flaky_key is present and unseen, returns 500 once.
#   POST /v1/tool    body: {"name":str,"latency":s}  sleeps, returns a result.
#   GET  /v1/stream?tokens=N&interval=s   SSE stream of N token deltas.
#
# Run: ruby fake_llm_server.rb [port]    (default 9944)

require "async"
require "async/http"
require "json"

port = Integer(ARGV[0] || ENV.fetch("PORT", 9944))
endpoint = Async::HTTP::Endpoint.parse("http://127.0.0.1:#{port}", backlog: 1024)

seen_flaky = {}
mutex = Mutex.new

json = ->(obj, status = 200) do
  Protocol::HTTP::Response[status, {"content-type" => "application/json"}, [JSON.dump(obj)]]
end

app = ->(request) do
  path, query = request.path.split("?", 2)

  case [request.method, path]
  in ["POST", "/v1/chat"]
    body = JSON.parse(request.body.read)
    if (key = body["flaky_key"]) && mutex.synchronize { seen_flaky[key] ? false : (seen_flaky[key] = true) }
      next json.({error: "synthetic 500 for #{key}"}, 500)
    end
    sleep body.fetch("latency", 0.2)
    turn = body.fetch("turn", 0)
    if turn < 2
      tools = body.fetch("tools", 4)
      json.({tool_calls: tools.times.map { |i| {id: "call_#{body["run"]}_#{turn}_#{i}", name: "search", args: {q: "query #{i}"}} }})
    else
      json.({content: "final answer for run #{body["run"]}"})
    end

  in ["POST", "/v1/tool"]
    body = JSON.parse(request.body.read)
    sleep body.fetch("latency", 0.1)
    json.({result: "result of #{body["name"]}"})

  in ["GET", "/v1/stream"]
    params = (query || "").split("&").to_h { |kv| kv.split("=", 2) }
    tokens = Integer(params.fetch("tokens", 20))
    interval = Float(params.fetch("interval", 0.03))
    body = Protocol::HTTP::Body::Writable.new
    Async do
      tokens.times do |i|
        sleep interval
        body.write("data: #{JSON.dump({delta: "tok#{i} "})}\n\n")
      end
      body.write("data: [DONE]\n\n")
      body.close_write
    rescue Protocol::HTTP::Body::Writable::Closed
      # client went away mid-stream; nothing to clean up
    end
    Protocol::HTTP::Response[200, {"content-type" => "text/event-stream"}, body]

  in ["GET", "/health"]
    json.({ok: true})

  else
    json.({error: "no route #{request.method} #{path}"}, 404)
  end
end

Sync do
  server = Async::HTTP::Server.for(endpoint, &app)
  STDERR.puts "fake llm listening on #{port}"
  server.run
end
