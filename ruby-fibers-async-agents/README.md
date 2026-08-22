# Ruby fibers and async for agent loops

An introduction to fibers, the fiber scheduler, and the async gem, written for
running LLM agent loops on them. Ruby 4 only. Every number in the guide was
measured here: nine runnable experiments, executed on Ruby 4.0.2 (built from
source via rbenv) with async 2.44.1 and async-http 0.101.0, outputs captured
verbatim.

## The short version

- A task costs 27us to create and ~14KB of RSS; a thread costs 425us and
  ~27KB (`02_task_cost.rb`, 5000 of each).
- Plain `Net::HTTP` and raw `TCPSocket` park the fiber with zero changes:
  10 requests against a 0.3s-latency server complete in 0.31s inside one
  reactor (`03_park_proof.rb`).
- 32 tool calls under `Async::Semaphore.new(8)` take exactly 4 waves:
  1.00s measured (`04_structured.rb`).
- 400 concurrent agent runs: task-per-run finishes in 2.24s where
  thread-per-run takes 4.54s and creates 3600 native threads
  (`06_scale.rb`).
- On Ruby 4, `Timeout.timeout` inside a reactor delegates to
  `scheduler.timeout_after` (timeout.rb line 284), so it behaves; what nothing
  can interrupt is a blocking C call (`09_pitfalls.rb`).
- A driver that blocks in C serializes the whole reactor: 8 x 50ms
  simulated queries take 0.40s and freeze every other fiber; offloading to a
  thread and parking the fiber on `Thread::Queue#pop` gets 0.05s
  (`08_blocking_and_offload.rb`).

## Contents

- `index.html`: the guide. Open it in a browser; tabs are chapters; no build
  step. Every number links back to a script and its captured output.
- `notes.md`: the working log: API verification against installed gem source,
  dead ends, and raw findings.
- `experiments/`: the scripts, plus `outputs/` with their captured stdout.
  `fake_llm_server.rb` is a deterministic fake LLM API (JSON chat endpoint,
  flaky-once endpoint for retry demos, SSE streaming endpoint) used by
  experiments 05, 06, and 07.

## Running

Ruby 4.0+ with `gem install async async-http`.

```
cd experiments
ruby 01_fibers_raw.rb             # resume/yield, hand-rolled scheduler, hook counts
ruby 02_task_cost.rb              # 5000 threads vs 5000 tasks
ruby 03_park_proof.rb             # unmodified Net::HTTP parks the fiber
ruby 04_structured.rb             # barrier, semaphore, timeout, cancellation
ruby 05_agent_loop.rb             # the canonical agent loop, with retry + deadline
ruby 06_scale.rb                  # N=400 thread-per-run vs task-per-run (N env var)
ruby 07_streaming.rb              # SSE consumption with async-http
ruby 08_blocking_and_offload.rb   # blocking drivers, thread offload, publisher
ruby 09_pitfalls.rb               # CPU starvation, Timeout, locals, lost waits
```

05, 06, and 07 spawn `fake_llm_server.rb` themselves and clean it up.
