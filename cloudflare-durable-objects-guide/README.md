# Cloudflare Durable Objects: A Beginner's Guide

An interactive guide to Cloudflare Durable Objects, written in two registers:

1. **Explain Like I'm Five** — the entire concept as a story about magical clubhouses,
   each with a unique name on the door, one caretaker who reads letters one at a time,
   and a notebook that survives naps. No prior knowledge needed.
2. **The engineering track** — the same ideas restated precisely for a professional
   software engineer: the actor-model mental picture, a deployable first object,
   the Storage/Alarms/WebSocket-Hibernation APIs, lifecycle and eviction semantics,
   production patterns and pitfalls, pricing/limits, and when to choose KV, D1, R2,
   or Queues instead.

## Contents

- [`index.html`](index.html) — the guide itself: a self-contained tabbed dashboard
  (12 tabs, left-hand nav, light/dark theme, no external dependencies beyond the
  JetBrains Mono webfont).
- [`notes.md`](notes.md) — research log: which Cloudflare docs pages were consulted,
  what was confirmed or corrected along the way (e.g. `getByName()` as the modern
  addressing shortcut, SQLite as the only backend for new accounts as of mid-2026,
  the `web_socket_auto_reply_to_close` compat flag), and the design decisions behind
  the report.

## Method

Content was sourced from current Cloudflare documentation via the Cloudflare
Developer Platform MCP server rather than from model memory, with pricing and
API details cross-checked against the docs' own changelog entries (SQLite GA
April 2025, free-plan availability April 2025, storage billing January 2026,
declarative `exports` config June 2026). Docs current as of August 2026.
