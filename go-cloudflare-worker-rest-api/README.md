# Building & Deploying a Go REST API on Cloudflare Workers

A beginner-friendly, standard-library-first tutorial. The full interactive version is
**[index.html](./index.html)** — a tabbed dashboard covering setup, code, deploy, and cost.

## TL;DR

Cloudflare Workers run on V8 isolates, not servers, so Go can't run natively — it compiles to
**WebAssembly**. The [`syumai/workers`](https://github.com/syumai/workers) package bridges the
Worker's `fetch` event to a plain `net/http.Handler`, so your code stays almost entirely
standard library. Since Go 1.22 the stdlib `http.ServeMux` does method + path-param routing
(`GET /books/{id}`), so you need **zero** third-party frameworks.

## What's here

| File | What it is |
|---|---|
| `worker/main.go` | A complete books CRUD REST API — stdlib `net/http` + `encoding/json` only |
| `worker/go.mod` | Module file (the one external dep: `syumai/workers`) |
| `worker/wrangler.toml` | Cloudflare deploy config, with KV + CPU-limit examples |
| `worker/Makefile` | `make dev` / `make build` / `make build-tinygo` / `make deploy` |
| `notes.md` | Research log + the key tradeoffs I worked through |
| `index.html` | The interactive tutorial dashboard |

## Quick start

```bash
# 1. Scaffold from the official template (installs Node deps + Go module)
npm create cloudflare@latest -- \
  --template github.com/syumai/workers/_templates/cloudflare/worker-go

# 2. Drop in the handler from worker/main.go, then run locally
npm start            # → http://localhost:8787
curl localhost:8787/books

# 3. Ship it to the edge
npx wrangler deploy  # → https://books-worker.<you>.workers.dev
```

## The one tradeoff that matters

- **Regular Go** = full standard library, but a 3–8 MB `.wasm` that usually exceeds the
  **3 MB free-plan** Worker limit → needs the paid plan.
- **TinyGo** = sub-1 MB binary that fits the free plan, at the cost of a reduced stdlib.

For a JSON API, develop with regular Go (everything works) and switch the build to TinyGo
(`make build-tinygo`) for free-tier deploys.

## Cost in one line

**Free:** 100k requests/day, 10 ms CPU each, $0. **Paid:** $5/mo for 10M requests + 30M CPU-ms,
then $0.30/M requests and $0.02/M CPU-ms. Wall-clock waiting is never billed — only CPU.

## Sources

- [syumai/workers](https://github.com/syumai/workers) ·
  [worker-template-go](https://github.com/syumai/worker-template-go)
- [Cloudflare Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) ·
  [limits](https://developers.cloudflare.com/workers/platform/limits/)
