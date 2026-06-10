# Notes — Go REST API as a Cloudflare Worker

## The core constraint I had to design around

Cloudflare Workers do **not** run native binaries. They run on V8 isolates — the same
engine as Chrome — which execute JavaScript and **WebAssembly**. So "Go on a Worker" really
means: compile Go → WASM, ship the `.wasm` alongside a small JS shim that boots it and
forwards `fetch` events into the Go program.

The bridge that makes this ergonomic is **`github.com/syumai/workers`**. It lets you write a
plain `net/http.Handler` and hands it the incoming request, so 95% of the code is ordinary,
boring, standard-library Go. That's exactly what the user asked for (stdlib first).

## Two ways to compile, and the tradeoff that actually matters

| | Regular Go (`GOOS=js GOARCH=wasm`) | TinyGo |
|---|---|---|
| stdlib support | full | partial (reflection/some pkgs limited) |
| `.wasm` size | large (often 3–8 MB) | small (often < 1 MB) |
| Fits **free** plan? (3 MB Worker limit) | usually **no** | yes |
| Fits **paid** plan? (10 MB limit) | yes | yes |

This is the crux. The user wants both "stdlib everywhere" *and* "tell me about the free tier."
Those pull in opposite directions:
- Full stdlib (regular Go) → binary too big for the free 3 MB Worker size limit → needs paid.
- Free tier → TinyGo → smaller stdlib subset.

Resolution I went with in the tutorial: **develop and learn with regular Go** (everything just
works), then **switch the build to TinyGo for free-tier deploys**. For a simple JSON REST API,
TinyGo handles `encoding/json`, `net/http` routing via the shim, and `net/http.ServeMux` fine.

## Routing: no framework needed (Go 1.22+)

Go 1.22 upgraded the stdlib `http.ServeMux` to support method + wildcard patterns:
`mux.HandleFunc("GET /books/{id}", ...)` and `r.PathValue("id")`. This means a real REST API
with path params and method matching needs **zero** third-party router. Great for a stdlib-first,
beginner-friendly tutorial. Confirmed this is the approach in the sample `main.go`.

## Pricing / limits (verified against Cloudflare docs, Jun 2026)

Free plan:
- 100,000 requests/day (resets 00:00 UTC)
- 10 ms CPU time per invocation
- 3 MB max Worker size (after compression)
- $0

Paid ("Workers Standard") — $5/mo minimum:
- 10,000,000 requests/month included, then **$0.30 / additional million**
- 30,000,000 CPU-milliseconds/month included, then **$0.02 / additional million CPU-ms**
- Default CPU limit 30 s/invocation, max 5 min (15 min for cron/queue consumers)
- 10 MB max Worker size
- **Wall-clock duration is NOT billed** — only CPU time. Waiting on a fetch/DB is free.

### What can the free tier actually serve?
100k req/day ≈ **~1.16 requests/second sustained**, or bursty up to that daily cap. For a JSON
API doing a few ms of CPU each, you'll hit the request cap long before the CPU cap. Plenty for a
side project, a personal API, a webhook receiver, or low-traffic SaaS. The hard wall is the
**3 MB binary** — that's why TinyGo matters for $0 hosting.

### Rough cost at scale (paid)
- 5M req/mo, ~3 ms CPU each → under both included buckets → **$5/mo flat**.
- 50M req/mo, 5 ms each → requests overage (40M × $0.30) = $12 + CPU (250M used − 30M incl =
  220M × $0.02/M... wait, $0.02 per *million* → 220 × $0.02 = $4.40) → ~$5 + $12 + $4.40 ≈
  **~$21/mo**. Still cheap.

## Build/deploy workflow that works (verified against templates)

Modern scaffold (replaces the older `gonew` instructions):
```
npm create cloudflare@latest -- --template github.com/syumai/workers/_templates/cloudflare/worker-go
```
TinyGo variant: `.../worker-tinygo`. Requires Node+npm, Go 1.24+, and (for free tier) TinyGo
0.29+. Then `npm start` for local dev (wraps `wrangler dev`), `npx wrangler deploy` to ship.

Under the hood the build does two things: generate JS assets + `wasm_exec.js` glue, then
`GOOS=js GOARCH=wasm go build -o app.wasm .` (or `tinygo build -o app.wasm -target wasm .`).

## Things that bit / things to warn beginners about
- `main()` must call `workers.Serve(handler)` and **not return** — returning ends the program.
- No local filesystem, no goroutë-spawning long-lived background work between requests, no
  `os/exec`. It's a request/response sandbox.
- Cold-start: the WASM instantiates per isolate; keep the binary small to keep it snappy.
- Persistent state needs Workers KV / D1 / Durable Objects — module globals are per-isolate and
  ephemeral. The demo uses an in-memory map and explicitly calls this out as non-durable.

## Sources
- https://github.com/syumai/workers
- https://github.com/syumai/worker-template-go , .../worker-template-tinygo
- https://developers.cloudflare.com/workers/platform/pricing/
- https://developers.cloudflare.com/workers/platform/limits/
