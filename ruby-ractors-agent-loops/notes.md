# Ruby Ractors for Agent Loops — investigation notes

Goal: teach how Ractors work in Ruby, focused on building scalable agent loops
(home-rolled agent framework, not RubyLLM) that communicate with the UI via Pusher.
Cover Ractors vs threads, and implications when running under Sidekiq and Puma.

Environment: Ruby 3.3.6 (x86_64-linux) in the container. Ractors are experimental here.
Will note API changes in 3.4 / 3.5 (Ractor::Port, Ractor.shareable_proc, require-in-ractor fixes).

## Plan
1. Experiments (small scripts, run for real, outputs captured here):
   - 01: Ractor basics — spawn, message passing, isolation errors
   - 02: Shareability — what crosses the boundary by copy vs move vs shared
   - 03: Parallelism proof — CPU-bound work: threads (GVL-bound) vs ractors
   - 04: Blocking I/O — threads vs ractors (both fine; GVL released on I/O)
   - 05: Agent loop prototype — supervisor + agent ractors + event-bus ractor
     (event bus stands in for the Pusher publisher)
   - 06: Pitfalls — non-shareable objects, class instance vars, require inside ractors
2. Write up architecture guidance: Puma / Sidekiq / Pusher placement.
3. index.html tabbed dashboard (delegate implementation to Opus), per DESIGN.md.

## Log

### 01 basics (Ruby 3.3.6) — all confirmed
- `Ractor.new(arg) { }` + `#take`, `send`/`Ractor.receive`, `Ractor.yield` all work as documented.
- Block cannot capture ANY outer local — even a `rescue => e` variable that happens to
  shadow an outer `e` makes the block non-isolable (`ArgumentError: can not isolate a Proc`).
  Bit me for real: rescue-var collision from a previous begin/rescue block.
- Non-main ractors can't touch globals: `Ractor::IsolationError` on `$counter`.
- Unhandled exception in ractor → `Ractor::RemoteError` on `take`, with `#cause` set.

### 02 shareability (Ruby 3.3.6)
- Shareable as-is: Integer, Symbol, frozen String, deeply-frozen Array, Class, Module,
  isolated Proc. NOT shareable: mutable String, frozen Array w/ mutable element, plain Hash.
- `send` deep-copies (proved via object_id mismatch). `send(obj, move: true)` transfers
  ownership; sender then gets `Ractor::MovedError` on any access.
- `Ractor.make_shareable` deep-freezes in place; shareable objects cross by reference
  (same object_id on both sides).
- Gotcha: `Ractor.make_shareable(->(x){x+1})` at top level fails — "Proc's self is not
  shareable" (self is `main`). Works if lambda is built where self is shareable, e.g.
  `Integer.instance_exec { ->(x){ x+1 } }`.

### 03 parallelism — THE BIG FINDING
Container: 4 cores (nproc=4, no cgroup quota; fork ground-truth scales 3.5x).
- Ruby 3.3.6: 4x fib(32) serial 0.98s / 4 ractors 2.28s = **0.43x — SLOWER than serial**.
  Same for allocation-free while-loops (5.26s serial vs 7.78s ractors).
  RUBY_MAX_CPU / RUBY_MN_THREADS made no difference. strace: only 17 futexes, no lock storm.
  CPU-time measurement: ractors ran at 358% CPU but burned 33s CPU for 2.7s-serial-CPU of
  work → per-iteration cost explodes ~12x when >1 ractor executes simultaneously
  (cross-core contention on shared VM caches; single ractor alone runs full speed).
- Ruby 3.4.5 (prebuilt from ruby-builder): same pathology (ractor fib 2.22s vs 0.99s serial).
- Ruby 3.5.0-preview1: **fixed**. 4x fib(32): 0.27s vs 1.01s serial = 3.7x speedup at
  386% CPU with NO extra CPU burn. While-loops: 2.74s → 0.69s = 3.97x.
- Ractor spawn+join cost: ~3ms (Ruby 3.3).
- Lesson for the report: for CPU-bound scaling you want Ruby 3.5+; on ≤3.4 ractors
  parallelize I/O-ish/independent work but can LOSE on hot pure-Ruby loops.
- 3.5.0-preview1 does not yet have Ractor::Port (that landed for 3.5 final); `take` still there.

### VERSION CORRECTION (from release notes research)
There is no Ruby 3.5 final: the 3.5 dev line was renumbered and shipped as **Ruby 4.0.0
on 2025-12-25**. So "3.5.0preview1" tested above is literally an early Ruby 4.0.
Ruby 4.0 Ractor changes (per rubyreferences/rubychanges + ko1's Ractor::Port article):
- `Ractor::Port.new` — only the creating ractor can `receive`/`close`; any ractor can
  `port << value` / `port.send(value, move: true)`.
- REMOVED: `Ractor.yield`, `Ractor#take`, `#close_incoming`, `#close_outgoing`.
- NEW: `Ractor#join`, `Ractor#value` (like Thread#join/#value), `Ractor.shareable_proc` /
  `shareable_lambda(self: ...)` — fixes the "Proc's self not shareable" pain directly.
- `Ractor.select` now takes ractors OR ports; `yield_value:`/`move:` params gone.
- Perf: official Tarai bench 3.87x on 4 ractors — matches my 3.7x fib measurement.
  (heise: reduced global-lock contention + less shared internal data = less cache contention.)

### 04 I/O-bound (Ruby 3.3.6)
8 simulated LLM calls (300ms blocking TCP): serial 2.41s, threads 0.31s, ractors 0.31s.
=> For I/O-bound agent work THREADS ALREADY SCALE (GVL released while blocked).
Ractors buy nothing for the waiting-on-the-API part. They buy CPU parallelism only.

### 05 agent loop prototype (Ruby 3.3.6) — WORKS
Topology: main supervisor -> pipe ractor (job queue; workers pull => load balancing)
-> 4 worker ractors (each runs multi-turn agent loop: fake LLM -> tool -> repeat)
-> bus ractor collecting events (stand-in for the Pusher publisher).
8 agents x 3 turns on 4 workers: 0.55s (serial ~2.8s). 48 events, ordered per-agent.
Gotchas hit for real:
- `%w[search calculate].freeze` is a frozen array of MUTABLE strings -> constant not
  shareable -> workers die with IsolationError; supervisor then HANGS in Ractor.select.
  Fix: `# frozen_string_literal: true` magic comment (or map(&:freeze)).
- Tools must not be top-level lambdas (self=main not shareable). Module + module_function
  works great and is closer to real framework shape anyway.
- Ractor objects ARE shareable: workers get the bus ractor as an arg and .send to it.

### 06 pitfalls (3.3.6 / 3.4.5 / 4.0-preview)
- require inside ractor: 3.3 IsolationError (RUBYGEMS_ACTIVATION_MONITOR); 3.4+ OK
  (require is delegated to the main ractor).
- net/http INSIDE a ractor: FAILS on all three (IsolationError on Net::HTTP::SSL_IVNAMES;
  freezing those constants just moves the failure to Timeout::TIMEOUT_THREAD — a global
  Thread, fundamentally unshareable). => stdlib HTTP cannot run in ractors today.
  Raw TCPSocket works fine in ractors (exp 04).
- pusher gem (2.1.1, uses httpclient): Client.new works inside a ractor, but
  `client.trigger` dies: "defined with an un-shareable Proc in a different Ractor".
  => Pusher publishing MUST live in the main ractor. Publisher-owner pattern.
- JSON generate/parse in ractor: OK. ENV reads: OK. Time.now/rand/SecureRandom: OK.
- Class ivar memoization (`@settings ||=` on a class): "can not set instance variables of
  classes/modules by non-main Ractors". Eager `Ractor.make_shareable` const is the fix.

### THE SIDEKIQ/PUMA LANDMINE (all versions incl. 4.0-preview)
`Array.new(3) { Thread.new { Ractor.new { ... }.take } }.map(&:value)` DEADLOCKS the
whole process. One thread doing this: fine. Three concurrently: wedged — and the process
ignores SIGTERM (needed SIGKILL). Known upstream: Bug #17826 "Ractor#take hangs if used
in multiple Threads", #21037 "Ractors hang with multiple threads" (code has literal
"TODO: make multithreaded"). Sidekiq runs jobs on N threads; Puma serves requests on N
threads => "spawn a ractor per job/request and wait on it" is a process-killer pattern.
Correct pattern: ONE owner thread per process owns all ractor lifecycle (persistent pool,
jobs in via pipe/port, results out via port/queue back to waiting threads).

### Environment note
Prebuilt rubies from ruby-builder toolcache need to live at /opt/hostedtoolcache/Ruby/
<ver>/x64 (baked RbConfig prefix) or stdlib requires fail. Symlinked from scratchpad.
gem install worked through the proxy (pusher 2.1.1 + httpclient 2.9.0).

## 2026-08-22: Ruby-4 rewrite
User request: assume Ruby 4, strip Ruby 3 material, add Async Ruby, apply their
unslop skill (fetched from github.com/tmatti/skills, applied to all new prose).
Plan: build real Ruby 4.0.2 from source (no prebuilt toolcache tarball for 4.x;
rbenv has a 4.0.2 definition), port every experiment to the Port API, re-measure
everything, add async experiments (async gem I/O concurrency, async inside a
ractor, hybrid async + ractor pool), then have Opus rewrite index.html.
Open questions to settle on the real build:
- Port receive is creator-only. The 4.0 sketch in the current report has workers
  receiving from a main-created jobs port. Probably wrong. Test.
- Does the multi-thread wait deadlock still reproduce with #value on 4.0.2?
- net/http and the pusher gem inside a ractor on 4.0.2?
- Does the async gem run inside a ractor?

### Answers (ruby 4.0.2, built from source via rbenv, ~9 min)
- API surface: take/yield gone, value/join/Port/shareable_proc/shareable_lambda
  present. Ractor.select over ports returns [port, msg]. Ractor.current can be
  sent through a port (workers can self-register).
- Port receive from a non-creator raises "only allowed from the creator Ractor
  of this port". So the old report's 4.0 sketch WAS wrong. Correct topology:
  workers push themselves into a ready_port; supervisor receives an idle worker
  and sends the job to its inbox; results/events come back on ports. One select
  over all three ports runs the whole thing. 05 rewritten this way: 8 agents,
  4 workers, 0.55s, all 48 events captured (needed an explicit event-count
  drain condition; results can arrive before their own completion events).
- CPU scaling on 4.0.2: 4x fib(32): serial 0.89s, threads 0.93s (0.96x),
  ractors 0.24s (3.77x), forks 0.23s (3.80x). Ractors now match forks.
- FIXED on 4.0.2 vs the 3.x/preview findings:
  * net/http inside a ractor WORKS (HTTP 200 against local server).
  * Timeout.timeout inside a ractor WORKS.
  * Multi-thread ractor waits: no deadlock at 3 or 8 concurrent Thread->value.
- Still broken: pusher gem trigger inside a ractor ("defined with an
  un-shareable Proc in a different Ractor", httpclient internals). Class-ivar
  lazy memoization still raises. Globals still main-only. So the publisher
  stays in the main ractor for gem-compat reasons.
- async gem (2.44.1) on 4.0.2:
  * 50 concurrent 300ms calls: threads 0.34s, async tasks 0.32s. Same wall
    time, but async used one thread for all 50.
  * Async::Semaphore(8) over 32 calls: 1.21s = four 0.3s waves. The "at most
    8 tool calls in flight" shape.
  * async runs INSIDE a ractor (3 concurrent socket calls, OK).
  * Ractor#value inside an async task blocks the whole reactor thread
    (0.5s ractor wait + 0.3s I/O ran serially: 0.80s). Not scheduler-aware.
  * The bridge: ractor owner THREAD + Thread::Queue. Queue#pop parks the
    fiber, not the thread, so I/O overlaps CPU: 0.30s total. This is the
    hybrid architecture: async reactor for LLM I/O, ractor pool behind an
    owner thread for CPU, Queue as the seam.
- Removed 03b (it explained the Ruby-3 slowdown; a Ruby-4 report doesn't need it).
- outputs.txt regenerated entirely from 4.0.2 runs.

## Report plan (index.html)
Tabbed dashboard (left tabs, dark default, JetBrains Mono, woodsy palette per DESIGN.md):
1. TL;DR & decision guide  2. Ractor fundamentals (3.x API + 4.0 Ports)
3. Shareability & the boundary  4. Ractors vs threads (benchmarks)
5. Agent loops on ractors (architecture + annotated code)
6. Pusher integration  7. Sidekiq & Puma  8. Pitfalls & production checklist
9. Experiments (scripts + real outputs)
HTML implementation delegated to Opus per user request.
