# Shared helpers: spawn the fake LLM server as a child process, wait for it,
# kill it on exit. Also RSS and clock helpers.

require "net/http"
require "json"

FAKE_LLM_PORT = Integer(ENV.fetch("PORT", 9944))

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

def rss_kb
  File.read("/proc/self/status")[/VmRSS:\s+(\d+)/, 1].to_i
end

def with_fake_llm(port: FAKE_LLM_PORT)
  pid = Process.spawn(RbConfig.ruby, File.join(__dir__, "fake_llm_server.rb"), port.to_s,
                      err: File::NULL)
  deadline = now + 10
  begin
    Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/health"))
  rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
    raise "fake llm server never came up" if now > deadline
    sleep 0.05
    retry
  end
  yield port
ensure
  begin
    Process.kill(:TERM, pid)
    Process.wait(pid)
  rescue Errno::ESRCH, Errno::ECHILD
  end
end

def post_json(port, path, payload)
  res = Net::HTTP.post(URI("http://127.0.0.1:#{port}#{path}"), JSON.dump(payload),
                       "content-type" => "application/json")
  [res.code.to_i, JSON.parse(res.body)]
end
