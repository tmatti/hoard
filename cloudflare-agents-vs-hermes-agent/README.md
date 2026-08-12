# Cloudflare Agents vs Hermes Agent

A fair, dimension-by-dimension comparison of two ways to build/host AI agents:

- **Cloudflare Agents** — a managed developer platform: each agent session is a
  Durable Object with embedded SQLite, deployed on Cloudflare's edge,
  TypeScript/JavaScript on the Workers runtime.
- **Hermes Agent** (Nous Research) — a self-hosted, MIT-licensed personal agent
  in Python with a self-improving skills/memory loop, a 25+ platform messaging
  gateway, and 100+ model providers.

## Contents

- [notes.md](notes.md) — research log with sourced findings
- [index.html](index.html) — interactive tabbed report (dark/light, ten
  comparison dimensions, summary table, recommendations, verdict)

## Method

Hermes facts were pulled from the GitHub repo (README, file tree) and the
official docs site (memory, tools, providers, architecture, messaging pages)
on 2026-08-11. Cloudflare claims supplied in the prompt were spot-checked
against developers.cloudflare.com/agents. Nous Portal pricing from web search.

## Headline conclusion

They are mostly **not** direct competitors. Cloudflare Agents is
infrastructure for shipping *agent products* (multi-tenant, one Durable Object
per user session, autoscaling). Hermes is a finished *personal agent
application* you run for yourself (one process, your hardware, learning loop,
every chat platform). They overlap only in the narrow "I want one agent that
talks to me over chat and does tasks" case — where the real question is
build-vs-adopt, not platform-vs-platform.
