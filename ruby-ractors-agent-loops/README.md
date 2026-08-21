# Ruby Ractors for Agent Loops

An empirical investigation into building scalable LLM agent loops on Ruby Ractors —
what Ractors actually give you over threads, how to structure a supervisor / worker-pool /
event-bus topology for a home-rolled agent framework, where Pusher publishing has to
live, and the operational landmines when Sidekiq and Puma enter the picture.

Everything in the report was **measured, not assumed**: seven runnable experiments were
executed on Ruby 3.3.6, Ruby 3.4.5, and a Ruby 4.0 preview build in a 4-core container.

## Headline findings

| Finding | Evidence |
|---|---|
| Ractors are **slower than serial** for CPU work on Ruby 3.3/3.4 (0.43x) — they parallelize (358% CPU) but burn ~12x cycles/iteration on cross-core VM cache contention | `experiments/03*.rb` |
| Ruby 4.0 fixes it: **3.74x speedup** on 4 cores (official Tarai bench: 3.87x) | cross-version runs |
| For I/O-bound work (LLM calls!) threads and ractors are **identical** — the GVL is released while blocked | `experiments/04_io_bound.rb` |
| A full agent-loop topology (supervisor → job pipe → 4 workers → event bus) works today on 3.3: 8 three-turn agents in 0.55s with per-agent ordered events | `experiments/05_agent_loop.rb` |
| `net/http` **cannot run inside a ractor** on any current Ruby (unshareable `SSL_IVNAMES`, then the fundamentally unshareable `Timeout::TIMEOUT_THREAD`); the `pusher` gem's `trigger` dies too → publish from the main ractor | `experiments/06_pitfalls.rb` |
| Multiple threads concurrently spawning/waiting on ractors **deadlocks the process** (ignores SIGTERM) on 3.3, 3.4 *and* the 4.0 preview — the exact shape of "spawn a ractor per Sidekiq job" | `experiments/07_thread_ractor_deadlock.rb`, upstream bugs #17826 / #21037 |

## Contents

- `index.html` — interactive tabbed report (open in a browser; dark/light, no build step)
- `notes.md` — working log: everything tried, in order, including the dead ends
- `experiments/01–07_*.rb` — runnable proofs for every claim (Ruby ≥ 3.3, no gems needed
  except `pusher` for one section of 06)
- `experiments/outputs.txt` — captured outputs from the runs behind the report

## Running

```
cd experiments
ruby 01_basics.rb           # spawn, messaging, isolation errors
ruby 02_shareability.rb     # copy vs move vs share
ruby 03_parallelism.rb      # threads vs ractors, CPU-bound
ruby 04_io_bound.rb         # threads vs ractors, I/O-bound
ruby 05_agent_loop.rb       # the full agent-loop-on-ractors prototype
ruby 06_pitfalls.rb         # require / net/http / class ivars / ENV in ractors
ruby 07_thread_ractor_deadlock.rb  # the Sidekiq-shaped deadlock (self-terminating)
```
