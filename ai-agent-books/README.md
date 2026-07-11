# Books for Building AI Agents — A Survey (mid-2026)

A verified survey of book-length treatments for software engineers building LLM-based
agentic systems and multi-agent architectures in **mid-2026**: agent loops, tool/function
calling, RAG & memory, prompt/context engineering, evaluation, orchestration, and
multi-agent design.

Every title was cross-checked against **both** a publisher page and a retailer/Goodreads
page before inclusion. Ratings are real Goodreads numbers (value **and** count), snapshotted
2026-07-10 — not stars-only, not invented. Unverifiable fields are marked `n/a`;
forthcoming and early-access (MEAP) titles are flagged.

## Contents
- `index.html` — interactive tabbed dashboard (dark-mode, left-side tabs, JetBrains Mono,
  woodsy palette, light/dark toggle). Open in any browser. Tabs: overview · hands-on
  engineering · multi-agent & orchestration · theory & background · compare all (sortable
  table) · reading paths · gaps & non-books · method & sources.
- `notes.md` — full research log with per-book verification and source URLs.
- `notes-reception.md` — supplementary community-reception research (HN, ratings, gaps).

## The short answer
1. **Start:** *AI Engineering* — Chip Huyen (O'Reilly, 2025) — GR **4.38 / 1,226**. The single
   most-cited, most-read, best-rated practical title. Evals, RAG, prompt eng, agents, production.
2. **Internals:** *Build a Large Language Model (From Scratch)* — Sebastian Raschka (Manning,
   2024) — GR **4.60 / 354**, the highest-rated book in the survey. Buy it to debug agent behaviour.
3. **Multi-agent:** *Building Applications with AI Agents* — Michael Albada (O'Reilly, 2025) for
   framework-comparative orchestration; *Agentic Design Patterns* — Antonio Gulli (Springer, 2025)
   for the pattern catalogue.
4. **Theory (optional):** *An Introduction to MultiAgent Systems* — Wooldridge (Wiley, 2009) for
   timeless concepts — but zero LLM content.

## Headline findings
- **24 real books** verified across foundations, agent-specific engineering, frameworks,
  multi-agent/orchestration, theory, and forthcoming/early-release.
- **No settled canon yet.** Every practical *agent-titled* book shipped in the last ~18 months and
  sits on a thin 30–75-vote Goodreads base. Only Huyen (1,226), Raschka (354) and Hands-On LLMs
  (282) have both high averages and meaningful samples. Weigh author/publisher over star averages.
- **Fast decay.** "The shelf life of AI education has collapsed from years to months." Anything
  with a framework name in the title has a ~12-month useful life — LangGraph v1.0 (Oct 2025),
  AutoGen 1.0 GA (Feb 2026), and MCP (Nov 2024, already forcing 2nd editions). Buy patterns,
  internals and theory for durability; use essays/docs for the frontier.
- **The frontier is un-booked.** For MCP, agent evals, context engineering, guardrails, and
  multi-agent-in-production, the honest best resource is still an essay/spec/docs — most notably
  Anthropic's *Building Effective Agents* (Dec 2024), which dominates community discussion more
  than any book. See the "gaps & non-books" tab.
- **No fabricated titles.** Every seed-list book resolved to a real, published (or genuinely
  in-progress) work. *AI Agents: The Definitive Guide* (Koenigstein, O'Reilly) is real but still
  early-release (final ~late 2026) — flagged as forthcoming.

## How to read the ratings
Goodreads is the consistent cross-title metric (Amazon star counts render client-side and can't
be scraped reliably). A 4.3 with 1,000+ ratings is a far stronger signal than a 3.9 with 40.
Thin-sample figures (<100 votes) are flagged throughout.
