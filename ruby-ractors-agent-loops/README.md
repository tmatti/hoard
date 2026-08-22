# Ruby Ractors for Agent Loops

How to run LLM agent loops on Ruby 4 with Ractors for CPU parallelism, Async
for I/O concurrency, and Pusher for streaming progress to the UI. Written for a
home-rolled agent framework running under Puma and Sidekiq.

Every number was measured, not quoted. Eight runnable experiments, executed on
Ruby 4.0.2 (built from source) in a 4-core Linux container.

## What the measurements say

| Finding | Evidence |
|---|---|
| Ractors match forked processes for CPU work: 3.77x vs 3.80x on 4 cores (threads: 0.96x, the GVL) | `experiments/03_parallelism.rb` |
| For I/O, threads, ractors, and async tie exactly. The GVL releases on blocking I/O, so the LLM-call layer never needed ractors | `04_io_bound.rb`, `08_async.rb` |
| A port-based agent-loop topology (ready port + results port + events port, one `Ractor.select`) runs 8 three-turn agents on 4 workers in 0.55s with all 48 events in order | `05_agent_loop.rb` |
| `net/http` and `Timeout.timeout` now work inside ractors. The `pusher` gem still does not (`httpclient` carries un-shareable procs), so publishing stays in the main ractor | `06_pitfalls.rb` |
| The old multi-thread ractor-wait deadlock is gone: 8 threads blocking in `Ractor#value` at once all complete | `07_thread_ractor_deadlock.rb` |
| `async` runs inside a ractor. Waiting on a ractor from inside a reactor blocks every fiber in that thread; a `Thread::Queue` bridge to an owner thread restores overlap (0.80s serialized vs 0.30s bridged) | `08_async.rb` |

## Contents

- `index.html`: the interactive report. Open it in a browser; no build step.
- `notes.md`: the working log, including the Ruby 3 era findings this report
  replaced and the dead ends.
- `experiments/01-08*.rb` + `outputs.txt`: the scripts behind every claim and
  their captured output.

## Running

Ruby 4.0+ required. `gem install async pusher` for experiments 06 and 08.

```
cd experiments
ruby 01_basics.rb                  # ports, value/join, isolation errors
ruby 02_shareability.rb            # copy vs move vs share, shareable_proc
ruby 03_parallelism.rb             # serial / threads / ractors / forks
ruby 04_io_bound.rb                # the I/O tie
ruby 05_agent_loop.rb              # the full port topology
ruby 06_pitfalls.rb                # what breaks inside ractors, what doesn't
ruby 07_thread_ractor_deadlock.rb  # the old landmine, retested
ruby 08_async.rb                   # async gem, and the ractor bridge
```
