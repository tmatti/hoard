# Notes: Ruby fibers + async for agent loops

Working notes, appended as I go.

## Setup

- Container ships Ruby 3.3.6. rbenv at /opt/rbenv has build definitions for 4.0.2.
- `rbenv install 4.0.2` kicked off with `MAKE_OPTS=-j$(nproc)`. The earlier
  ractors investigation in this repo also used 4.0.2, so the definition is known
  good here.
- Fetched the unslop skill from tmatti/skills and read it. Applies to all prose
  in this folder.

## Plan

Chapters map to tabs in index.html. Every chapter gets at least one runnable
script in experiments/, executed on the installed Ruby 4.0.2, output captured
into experiments/outputs/ and quoted verbatim in the guide.

1. Fibers raw: Fiber.new/resume/yield, hand scheduling pain, Fiber::Scheduler
   hook, blocking vs scheduled sleep demo.
2. async gem: Async/Sync, task cost vs thread cost (memory + creation time at
   a few thousand each), Net::HTTP parking the fiber unmodified.
3. Structured concurrency: barrier, semaphore (measure 32 calls / 8 slots),
   with_timeout, stop propagation, ensure semantics mid-I/O.
4. Agent loops: fake LLM server (deterministic, latency via sleep, SSE
   endpoint), agent runner demo, thread-per-run vs fiber-per-run at hundreds
   of concurrent runs, SSE streaming consumption with async-http.
5. Architecture: runner process vs Sidekiq vs Falcon, DB driver blocking demo,
   publisher task with backpressure, CPU offload to a thread via Queue#pop.
6. Pitfalls: each one a misbehaving script.
7. Decision guide: prose only.

## Environment landed

- `rbenv install 4.0.2` built clean (~6 min with -j4). `gem install async async-http`
  gave async 2.44.1, async-http 0.101.0, protocol-http 0.71.0.
- Loading async on Ruby 4.0.2 prints `IO::Buffer is experimental` once per
  process on stderr. Harmless, comes from io-event. Left it in captured outputs.

## API verification against async 2.44.1 (installed source, not memory)

- `Async::Semaphore.new(limit = 1, parent: nil)`, `#async` spawns through it.
- `Async::Barrier#wait` waits tasks in completion order and re-raises child
  errors; `#stop` is now a deprecated alias for `#cancel`.
- `Task#stop` and `Task#cancel` both exist; 2.44 renamed the concept to cancel.
  `Async::Stop` is now `Async::Cancel` and it derives from Exception, not
  StandardError, so a bare `rescue => e` will not swallow cancellation.
- `Task#with_timeout(duration, exception = TimeoutError)` confirmed at
  task.rb:153.
- `Async::LimitedQueue` exists (limited_queue.rb) for bounded queues.
- async-http: `Async::HTTP::Server.for(endpoint) { |req| Protocol::HTTP::Response[...] }`,
  `Async::HTTP::Internet#get/post` defined dynamically from Protocol::HTTP::Methods,
  streaming via `Protocol::HTTP::Body::Writable` (#write, #close_write).

## Ruby 4 Fiber::Scheduler additions (release notes, cross-checked)

Release announcement lists: `fiber_interrupt` (interrupt a parked fiber when
its IO closes), `Fiber::Scheduler#yield`, `io_close` hook reintroduced,
`io_write` invoked when flushing buffers. Plus `Fiber#raise(cause:)`.
Cross-check against async 2.44.1: it implements fiber_interrupt but NOT
io_close. Found out the hard way: defining io_close on a subclass makes CRuby
call it (Ruby 4 honors the hook), and super then explodes with NoMethodError.
Kept the discovery in notes; experiment only wraps hooks the superclass has.

## Experiments 01-04 (first results)

- 01: raw fibers + hand-rolled IO.select loop works but is ~25 lines of
  scheduler nobody wants to own. With Async::Scheduler installed the same
  `sleep 0.5` twice takes 0.5s not 1.0s. Hook counts: kernel_sleep 2, io_wait 2,
  block 3, unblock 1, address_resolve 1. Gotcha: the scheduler object must be
  created on the thread that uses it, else FiberError "fiber called across
  threads".
- 02: 5000 sleeping threads: 2.12s to create (425us each), 134MB RSS growth
  (26.9KB each). 5000 parked tasks: 0.137s (27us each), 69MB (13.7KB each).
  15x faster creation, 2x memory. The memory gap is smaller than folklore
  says; the creation and scheduling gap is the real story at this scale.
- 03: 10 plain Net::HTTP requests against a 0.3s-latency server inside one
  reactor: 0.31s total. Raw TCPSocket: same. Heartbeat ticked every 100ms
  throughout. No modification to Net::HTTP needed.
- 04: semaphore 32 calls/8 slots/0.25s = 1.0s measured exactly, peak 8.
  with_timeout raised at 0.30s. parent.stop returned in 0.3ms, ensure order:
  parent first, then subtrees in creation order (second subtree's cancels are
  deferred to the next loop pass; needed a 0.1s grace before reading the log).
  Stopping a task parked in a socket read ran its ensure and let it close the
  socket. Barrier.wait re-raised a child error; barrier.stop cancelled the
  surviving siblings.

## Experiments 05-09 (results)

- 05 agent loop: 3 concurrent runs, per-run critical path 0.9s (2 turns with
  tools + 1 final turn + one injected 500 and its 0.1s backoff), all 3 runs
  done in 0.92s. The event log shows the retry at 0.31s and the backoff sleep
  parking the fiber.
- 06 scale, N=400 runs (3 LLM calls + 8 tool calls each, ideal 0.8s/run):
  threads: wall 4.54s, p50 4.37s, RSS +74.6MB, 3600 native threads created,
  peak 979 alive. tasks: wall 2.24s, p50 2.10s, RSS +54.2MB, 0 threads.
  At N=100: threads 1.38s vs tasks 1.10s. The gap widens with N: 1.25x at
  100 runs, 2.0x at 400. Both are above the 0.8s ideal because a single
  fake-server process saturates; same server for both modes so the comparison
  holds. NOFILE was capped at 20000 in the container (setrlimit EPERM), fine
  for these N.
- 07 streaming: first SSE delta at 0.032s, 20th at 0.607s, mean inter-arrival
  28.8ms against a 30ms server interval. Three concurrent streams interleave:
  s0 s1 s0 s2 s0 s1 s2...
- 08 seams: 8 x 50ms Fiber.blocking "queries" serialize to 0.40s and each
  freezes the heartbeat for its full 50ms; offloaded to threads with the fiber
  parked on Thread::Queue#pop the same work takes 0.05s and the heartbeat
  stays at 20ms. Publisher demo: 60 events through a LimitedQueue(16), the
  producer spent 81ms blocked (backpressure works, nothing dropped), batches
  [10,10,10,10,10,10,1]. Cancel case: run stopped after 46/1000 events, the
  ensure block still enqueued the terminal event and the publisher delivered
  all 47.
- 09 pitfalls:
  - 30M plain increments froze the reactor 1065ms.
  - Timeout.timeout on Ruby 4 DELEGATES to scheduler.timeout_after when a
    scheduler is set (timeout.rb line 284). Measured: raises at 0.30s on a
    parked sleep, does NOT hit a bystander fiber (B2), and silently does
    nothing around a blocking C-style call (returned after the full 1.0s).
    So the old "Timeout.timeout corrupts the reactor" advice is stale on
    Ruby 4; the surviving advice is that nothing interrupts blocking C code,
    and exception classes differ (Timeout::Error vs Async::TimeoutError).
  - Thread.current[:x] is fiber-local (child sees nil); thread_variable_get
    is truly thread-wide; Fiber[:x] inherits into child fibers. Fiber[] is
    the right home for per-run context like run ids.
  - Bare increments from 10 tasks: 1000/1000, no lock needed. Put an await
    between read and write: 101/1000. Locks aren't the fix; not holding
    state across awaits is.
  - Forgotten barrier.wait: child error only shows up as a console warn line;
    caller continues. A forgotten sleeping child delays Sync exit by its full
    sleep (measured 1.00s).
  - Deterministic test: inject transport lambdas, Sync, zero latency: 3
    identical runs at 0.17ms mean.

## Claims verified against sources (not memory)

- pg gem: "Pg is fully compatible with Fiber.scheduler introduced in Ruby-3.0
  since pg-1.3.0" (rubydoc pg README). It uses libpq's nonblocking mode
  internally and routes waits through the scheduler.
- Ruby 4.0 release notes: Fiber::Scheduler gained fiber_interrupt,
  Fiber::Scheduler#yield, io_close (reintroduced), io_write on buffer flush.
- async 2.44.1: implements fiber_interrupt, does not implement io_close.

## Dead ends and gotchas hit along the way

- support.rb first version had `ensure` + method-level `rescue` mixed; Prism
  rejects it. Wrapped in begin/end.
- The CountingScheduler must be constructed on the thread that will run it
  ("fiber called across threads" otherwise).
- First publisher demo cancelled the producer before it printed its
  backpressure number; split into C1 (no cancel) and C2 (cancel + terminal).
- 04's stop-propagation demo initially printed the ensure log before the
  second subtree's deferred cancels ran; needed a 0.1s grace period.

## Deliverable

- index.html written as an 8-tab report per DESIGN.md: JetBrains Mono, OKLCH
  woodsy palette, left sidebar tabs (260px, drawer under 900px), light/dark
  with localStorage and a no-flash head script, restrained $ / ~/ accents.
- Rendered in headless Chromium (Playwright, both color schemes): no JS
  errors, tab routing and the theme toggle work, note/table/code components
  legible in both themes.
- Unslop pass: grepped the three prose files for em/en dashes, curly quotes,
  and the banned vocabulary list; zero hits. Headings are sentence case, no
  emojis, numbers stated concretely, opinions stated as opinions.
