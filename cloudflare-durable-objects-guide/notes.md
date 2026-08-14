# Notes — Cloudflare Durable Objects beginner's guide

Goal: a beginner's guide to Durable Objects with two registers — an ELI5 section
up front that anyone can follow, then the rest written for a professional
software engineer.

## Research log

### Sources
Used the Cloudflare Developer Platform MCP server (`search_cloudflare_documentation`)
to pull current docs rather than relying on memory. Key pages consulted:

- `/durable-objects/concepts/what-are-durable-objects/` — definition, features, highlights
- `/durable-objects/concepts/durable-object-lifecycle/` — stub creation vs instantiation, state transitions
- `/durable-objects/best-practices/access-durable-objects-storage/` — SQLite backend recommended, storage survives eviction
- `/durable-objects/best-practices/websockets/` — Hibernation WebSocket API, serializeAttachment
- `/durable-objects/best-practices/rules-of-durable-objects/` — hibernation best practices, `web_socket_auto_reply_to_close` flag
- `/durable-objects/reference/durable-object-class-migrations-legacy/` — migrations config (new_sqlite_classes etc.)
- `/workers/wrangler/configuration/` — `migrations` now called legacy; new declarative `exports` field (June 2026 changelog)
- `/durable-objects/platform/pricing/` — free/paid compute limits table (verbatim numbers), SQLite storage billing enabled Jan 2026
- Changelogs: DO free tier (Apr 2025), SQLite GA with 10GB (Apr 2025), Python DO support (May 2025), new KV-backed namespaces blocked for fresh accounts (Jul 2026)

### Things learned / confirmed along the way

- **The modern happy path is `getByName()`** — `env.MY_DO.getByName("foo")` replaces
  the two-step `idFromName()` + `get()` dance in current docs and examples. Kept the
  two-step form in the guide too since most existing tutorials use it.
- **SQLite backend is the default story now.** Free plan *only* supports SQLite-backed
  classes; as of mid-2026 accounts without an existing KV-backed namespace can't create
  new ones at all (`new_classes` migration fails with an error). Guide teaches
  `new_sqlite_classes` exclusively and mentions KV backend only as legacy.
- **`migrations` is now labeled "legacy"** in the wrangler config docs, in favor of a
  declarative `exports` field (changelog 2026-06-30). Mutually exclusive with
  `migrations`. Guide teaches `migrations` (it's what every tutorial and existing
  project uses) with a callout about `exports`.
- **Compute billing nuance**: duration is billed only while active or idle-but-unable-
  to-hibernate. An outbound WebSocket/TCP connection pins the object in memory for up
  to 15 min per connection — worth a pitfall entry.
- **`web_socket_auto_reply_to_close`** compat flag (default on for compat dates >=
  2026-04-07) removes the need to call `ws.close()` inside `webSocketClose()`. Older
  dates must call it or clients see 1006 errors.
- **Free plan hard numbers** (from pricing page, verbatim): 100k requests/day,
  13,000 GB-s duration/day, resets 00:00 UTC, operations fail with errors once
  exceeded. Paid: 1M req + 400k GB-s included, then $0.15/M req and $12.50/M GB-s.
- **SQLite storage billing** went live Jan 2026 (target Jan 7). Storage rates on the
  paid plan follow the Sept 2024 announcement (D1-parity style rows read/written +
  GB-month). Guide links to the pricing page for exact storage rates rather than
  hard-coding every number.
- **RPC billing gotcha**: each RPC session = one billed request; a method call on a
  stub is its own session, but calls on a returned `RpcTarget` stub ride the same
  session. Included in pricing tab.
- **10 GB SQLite per object** (GA Apr 2025; older concept page footnote saying 1 GB
  is stale — the GA changelog supersedes it).
- Single-threaded execution + input/output gates is the part beginners most
  misunderstand — gave it its own mental-model treatment (the "one clerk per
  mailbox" framing carries from the ELI5 section into the engineering sections).

### Design decisions for the report

- Tabbed dashboard per AGENTS.md/DESIGN.md: 260px left sidebar, JetBrains Mono,
  woodsy OKLCH palette (forest green accent, walnut warm), light/dark with
  localStorage + no-flash inline script, `~/` and `$` accents kept subtle.
- 12 tabs: Start Here / ELI5 / Mental Model / Your First Object / Storage API /
  Alarms / WebSockets / Lifecycle / Patterns & Pitfalls / Pricing & Limits /
  DO vs KV vs D1 / References.
- Tiny regex-based syntax tinting for code blocks (comments, strings, keywords)
  instead of shipping a highlighter library — keeps index.html self-contained.
- Hash-based routing so individual tabs are linkable; prev/next footer links so it
  also reads linearly like a guide.
- ELI5 uses a "clubhouse with one caretaker and a notebook" analogy, chosen because
  it maps 1:1 onto the real properties (unique name → address, one caretaker →
  single-threaded, notebook → durable storage, napping → hibernation) so the
  professional sections can call back to it.
