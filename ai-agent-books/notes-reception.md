# Companion notes — Community reception + gaps survey (2026-07-10)

Separate file to avoid clobbering the concurrently-edited notes.md.
Scope of THIS task: community reception (HN/Reddit/dev blogs), aggregate ratings,
gaps / best non-book resources, shelf-life.

## Method
- WebSearch + WebFetch. Reddit direct fetch BLOCKED. HN via Algolia API (works).
- Community sentiment mostly from HN threads + dev.to/Medium/KDnuggets listicles + Victor Dibia newsletter.
- 2 background agents: ratings, gaps.

## Consensus favorites (titles recurring across sources)
Foundation:
- AI Engineering — Chip Huyen (O'Reilly 2025). MOST cited. "Most read book on O'Reilly since release."
  Praise: production focus, evals for non-deterministic multi-step systems, low hype. Goodreads 4.38 / 1,226 (per notes.md cross-check).
- Build a Large Language Model (From Scratch) — Raschka (Manning 2024). "If you only read one book..." for LLM internals; not agent-specific.
- Hands-On Large Language Models — Alammar & Grootendorst (O'Reilly 2024). Visual, accessible; light on transformer internals; some content dates. Goodreads 4.29 / 282.
- LLM Engineer's Handbook — Iusztin & Labonne (Packt 2024). Full LLMOps, RAG+eval depth, observability, cost.
- Designing Machine Learning Systems — Chip Huyen (O'Reilly 2022). Pre-LLM; system-design thinking only.
- Building LLM-Powered Applications — Valentina Alto (Packt 2024). Hands-on LangChain/agents/memory; framework code dates.

Agent-specific:
- Designing Multi-Agent Systems — Victor Dibia (2025). Dibia's own top pick; framework-agnostic, first principles.
- Building Applications with AI Agents — Michael Albada (O'Reilly 2025). Multi-framework; "code ages fast." Goodreads 3.40 / 57.
- Building Agentic AI Systems — Biswas & Talukdar (Packt 2025). "Separates toy demos from robust agents."
- AI Agents in Action — Micheal Lanham (Manning 2025; 2nd ed 2026 +MCP/A2A). Goodreads 3.10 / 78 — lowest rated; 1st ed "tutorial notes," MCP absent.
- Generative AI Design Patterns — Lakshmanan & Hapke (O'Reilly 2025). 32 patterns; not fully agent-focused.
- AI Agents with MCP — Kyle Stratis (O'Reilly, expected LATE 2026). "First comprehensive book-length MCP guide" => no MCP book yet.

## Reception data points
- Anthropic "Building Effective Agents" essay = canonical go-to. HN 763pts/121c (2024-12-20) + 543pts/88c (2025-06-17). Far outweighs any book thread.
- Chip Huyen "Agents" blog (huyenchip.com/2025/01/07/agents.html) on HN 2025-01-11.
- HN Ask HN 2026-03-13 (id 47361403): recommends Raschka + Huyen AI Engineering.
- Book-vs-book Reddit threads sparse in search; consensus signal = same ~6 titles recurring across listicles.

## Shelf-life
- "Shelf life of AI education has collapsed from years to months" (labla.org, Mar 2026).
- 2022 books miss ChatGPT; 2023 miss agents; early-2024 treat GPT-4 as frontier.
- MCP (Nov 2024) already forcing 2nd editions (AI Agents in Action).
- Counterpoint: fundamentals compound; buy books for fundamentals, docs/papers/essays for frontier.
- Paulo Cysne "What AI Agent Books Still Get Wrong" (Medium Apr 2026): weak eng practices taught as normal, narrow coverage, bloat.

## Ratings (gathered; ratings-agent to confirm more)
- AI Agents in Action (Lanham, Manning 2025): Goodreads 3.10, 78 ratings / 18 reviews. https://www.goodreads.com/en/book/show/221160748-ai-agents-in-action
- AI Engineering (Huyen): Goodreads 4.38, 1,226 ratings (per notes.md). https://www.goodreads.com/book/show/216848047-ai-engineering
- Hands-On LLMs: Goodreads 4.29, 282 ratings. https://www.goodreads.com/book/show/210408850-hands-on-large-language-models
- Building Applications with AI Agents (Albada): Goodreads 3.40, 57 ratings.

## RATINGS AGENT RESULTS (2026-07-10, Goodreads primary/live; Amazon counts NOT FOUND — page JS shell/503; Amazon stars are secondary via awesome-llm-books, approximate)
| Book | Goodreads avg (n, reviews) | Amazon stars (count) |
|---|---|---|
| AI Engineering — Huyen (O'Reilly 2025) | 4.38 (1,226; 153) | ~4.7 (count NOT FOUND) |
| Hands-On LLMs — Alammar & Grootendorst (O'Reilly 2024) | 4.29 (282; 32) | ~4.7 (NOT FOUND) |
| LLM Engineer's Handbook — Iusztin & Labonne (Packt 2024) | 3.88 (69; 9) | ~4.6 (NOT FOUND) |
| Building LLM Powered Applications — Alto (Packt 2024) | 3.58 (36; 8) | ~4.2 (NOT FOUND) |
| Designing ML Systems — Huyen (O'Reilly 2022) | 4.44 (1,152; 116) | ~4.7 (NOT FOUND) |
| AI Agents in Action — Lanham (Manning 2025) | 3.10 (78; 18) | ~4.1 (NOT FOUND) |
| Learning LangChain — Oshin & Campos (O'Reilly 2025) | 3.79 (53; 12) | NOT FOUND |
| Building Agentic AI Systems — Biswas & Talukdar (Packt 2025) | 2.93 (30; 6) | NOT FOUND |
Note: Amazon rating COUNTS not obtainable for any book (blocked). Goodreads drifts daily; 2026-07-10 snapshot.
Extra real agent titles (few ratings): Building Agentic AI — Sinan Ozdemir (GR id 241823059); Agentic AI Engineering — Yi Zhou (GR id 241106813).

## GAPS AGENT RESULTS (2026-07-10) — topic | best non-book resource | URL
1. Agent design patterns / when to use agents — Anthropic "Building Effective Agents" (Dec 2024) https://www.anthropic.com/research/building-effective-agents (HN 763/121)
2. Production reliability — 12-factor agents (HumanLayer) https://github.com/humanlayer/12-factor-agents (~19.8k stars per GH search snippet; agent couldn't verify count)
3. MCP — official spec https://modelcontextprotocol.io (repo github.com/modelcontextprotocol/modelcontextprotocol). No MCP book yet (Stratis book late 2026).
4. Agent evals — Hamel Husain "Your AI Product Needs Evals" https://hamel.dev/blog/posts/evals/ (Mar 2024) + Anthropic "Demystifying evals for AI agents"
5. Context engineering — Anthropic "Effective context engineering for AI agents" (Sep 2025) https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
6. Multi-agent orchestration in prod — Anthropic "How we built our multi-agent research system" (Jun 2025) + LangGraph docs
7. Guardrails/prompt injection — Simon Willison "lethal trifecta" series https://simonwillison.net/series/prompt-injection/ + OWASP LLM cheat sheet
8. Observability/tracing — LangSmith / Langfuse / Braintrust docs
9. Cost/prompt caching — provider docs (Anthropic/OpenAI caching)
10. Foundational patterns — ReAct https://arxiv.org/abs/2210.03629 (Oct 2022) + Toolformer https://arxiv.org/abs/2302.04761 (Feb 2023)
11. Vendor playbooks — OpenAI "A Practical Guide to Building Agents" PDF + Google/Kaggle "Agents Companion" whitepaper
12. Staying current — DeepLearning.AI Agentic AI (Andrew Ng) https://www.deeplearning.ai/courses/agentic-ai + Latent Space, Simon Willison, Eugene Yan newsletters

Verified HN community sentiment — Ask HN "Learning resources for building AI agents?" https://news.ycombinator.com/item?id=47637083:
- "Just start building my man. Would highly advise keeping it minimal, just use OpenAI Agents SDK" — stochtinkerer
- "Text in, text out. It's all a bunch of prompts. Use the APIs directly and avoid as many abstraction layers" — adi_kurian
- Theme: learn by building + framework docs, not courses/books.

Caveats: reddit.com not fetchable this env — no verbatim Reddit quote captured (sentiment HN-sourced). 12-factor star count unverified by gaps agent.

Sub-agent working notes also at: book-ratings-survey/notes.md and agent-book-gaps/notes.md (sibling folders).
