# Athena — C4 Architecture

A C4-model walkthrough of the **Athena** personal-brain backend (`tmatti/athena`), preserved
as a hoard entry and **verified line-by-line against the source code**.

Athena is a single-user, self-hosted "personal brain": one Go binary serving a REST API
(`/v1`) *and* an MCP server (`/mcp`, or stdio via `--stdio`) on a single port (`:8080`), backed
by Postgres + pgvector. It stores **memories** (atomic facts, embedded whole) and **notes**
(documents chunked into `note_chunks`, embedded per chunk), and retrieves them with hybrid
keyword + vector search fused by Reciprocal Rank Fusion.

## What's here

- **`index.html`** — an interactive, tabbed dark-mode report. Left-rail navigation follows the
  C4 model top-down (L1 context → L2 containers → L3 components → data model), then the three
  runtime flows (save memory, save note, hybrid recall), then a **Verification & drift** tab
  that records the source-check results. All diagrams are rebuilt as native HTML/CSS — no
  Mermaid dependency — in the site's JetBrains Mono / woodsy palette, with a light/dark toggle.
- **`notes.md`** — the investigation log: sources, tooling friction, the full claim-by-claim
  verification table, and the drift findings.

## The report answers

1. **Do the artifact's claims match the current source?** Yes — essentially 100%. Every
   load-bearing number checks out: chunk sizes 1200/3000/300, RRF constant `k=60`, 40
   candidates per leg, retry batch 32, the immediate-then-4/8/16-min backoff, content-guarded
   embedding UPDATEs, the 9 MCP tools, the four-table schema.
2. **The three request lifecycles**, traced end to end from client to Postgres.
3. **The deliberate guarantees** — write-never-fails-on-embedding, the model-drift guard,
   keyword-freshness — and exactly how each is enforced in code.
4. **How the schema supports hybrid search** — generated `tsvector` (GIN) and `vector(1536)`
   (HNSW cosine) side by side — and the memories-vs-notes indexing asymmetry.

## Drift found (all minor)

The single concrete inaccuracy: the artifact footer points to `docs/architecture.md`, which
**does not exist** in `master`. The rest are enrichments the artifact under-specified — most
notably the `embed_last_attempt_at` backoff clock, that the `notes` table carries *no* search
index of its own (only `note_chunks` do), and that the drift guard auto-adapts vector
dimensions on first boot. See the **Verification & drift** tab or `notes.md` for the full list.

## Verified against

`tmatti/athena` — `master` @ `0bfdac90857896ab4a53c90ac1cee9aa8eedee93`
(source artifact `54dd644b-a88c-44e8-aac7-80f03b0d8324`).

The subject repo was read by cloning it fresh from GitHub; no copy of its source is included
here (only this new report and the notes).
