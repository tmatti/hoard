# Notes — Books on Building AI Agents & Multi-Agent Architectures

Investigation started 2026-07-10. Goal: survey the best currently available, highly
rated, up-to-date, practically relevant books for an engineer building LLM-based
agentic systems and multi-agent architectures in mid-2026.

## Constraints / ground rules
- Only include REAL, verifiable books. Verify publisher, author, date, rating with URLs.
- Weigh recency heavily — field moves fast. Flag stale content.
- Classic pre-LLM MAS theory allowed only if still earns its place; label as theory.
- Deliverable: tabbed dark-mode HTML dashboard + notes + README.

## Research plan
- Fan out research agents by category:
  1. Hands-on engineering books (O'Reilly / Manning / Packt) — agent loops, tools, RAG, memory, eval.
  2. Multi-agent architecture / orchestration books + classic MAS theory.
  3. Community reception (HN, Reddit, Goodreads/Amazon ratings) + gaps.
- Cross-verify each title exists before including.

## Log
- Created folder + notes.
- Spawned parallel research agents (see below for findings).

## Verified directly (cross-check)
- **AI Engineering: Building Applications with Foundation Models** — Chip Huyen, O'Reilly, 2025.
  ISBN 9781098166304. Goodreads 4.38 (1,226 ratings, 153 reviews). "Most read book on
  O'Reilly since release." Covers eval, prompt eng, RAG, fine-tuning, agents, AI stack.
  https://www.goodreads.com/book/show/216848047-ai-engineering
- **Hands-On Large Language Models: Language Understanding and Generation** — Jay Alammar &
  Maarten Grootendorst, O'Reilly, Oct 2024, 425pp. ISBN 9781098150969. Goodreads 4.29
  (282 ratings, 32 reviews). Praised by Andrew Ng. Strong visual/diagram-driven; covers
  embeddings, RAG, transformers. Agent coverage lighter — more LLM foundations than agents.
  https://www.goodreads.com/book/show/210408850-hands-on-large-language-models

---

## MULTI-AGENT SURVEY — VERIFIED FINDINGS (2026-07-10)

Scope narrowed to (A) multi-agent architecture/orchestration LLM-era + (B) classic MAS theory.
All entries below verified via publisher + retailer + Goodreads. Ratings are real numbers
pulled from Goodreads/retailer pages; "n/a" = too new / no rating surface yet.

### (A) PRACTICAL — LLM-era multi-agent / orchestration

A1. **Agentic Design Patterns: A Hands-On Guide to Building Intelligent Systems** — Antonio
    Gulli (Senior Director / Distinguished Engineer, Google CTO office). Springer Nature.
    eBook 2025-10-30, softcover 2025-10-31. ISBN 9783032014016 (print) / 9783032014023.
    424pp, 21 chapters + 7 appendices. Patterns: prompt chaining, routing, parallelization,
    reflection, tool use, planning, MULTI-AGENT collaboration, memory, MCP, HITL, RAG.
    Frameworks: LangChain/LangGraph, CrewAI, Google ADK. FREE preprint (Google Doc) + paid.
    Goodreads page exists (id 237795815) but rating n/a (very new). Very relevant mid-2026.
    https://link.springer.com/book/10.1007/978-3-032-01402-3
    https://www.amazon.com/Agentic-Design-Patterns-Hands-Intelligent/dp/3032014018

A2. **Building Applications with AI Agents: Designing and Implementing Multiagent Systems** —
    Michael Albada. O'Reilly, 2025-10-21. ISBN 9781098176501. Goodreads 3.40 (57 ratings,
    14 reviews). Covers agent core (tools/memory/orchestration), LangGraph, AutoGen, CrewAI,
    OpenAI SDK, coordination patterns, scalability, security, eval, human-agent collab.
    https://www.goodreads.com/en/book/show/230529414-building-applications-with-ai-agents

A3. **Learning LangChain: Building AI and LLM Applications with LangChain and LangGraph** —
    Mayo Oshin & Nuno Campos (Campos = founding engineer at LangChain, Inc.). O'Reilly,
    2025-03-25, 294pp. ISBN 9781098167288. Goodreads 3.79 (53 ratings, 12 reviews).
    RAG + LangGraph agent architecture, deployment, monitoring/eval. Authored by a LangGraph
    maintainer = the "author of the framework" pick.
    https://www.goodreads.com/book/show/220306097-learning-langchain

A4. **Agentic Architectural Patterns for Building Multi-Agent Systems** — Dr. Ali Arsanjani &
    Juan Pablo Bustos (Google Cloud). Packt, 2025. ISBN 9781806029570 (print) / ...563 (ebook).
    GenAI maturity model, hierarchical orchestrator/sub-agent architecture, A2A protocol, RAG,
    fine-tuning, LLMOps, fault tolerance. Rating n/a (new). Packt GitHub repo exists.
    https://www.packtpub.com/en-us/product/agentic-architectural-patterns-for-building-multi-agent-systems-9781806029570

A5. **Building Agentic AI: Workflows, Fine-Tuning, Optimization, and Deployment** — Sinan
    Ozdemir. Addison-Wesley Professional (Pearson AI Signature Series), 2025-11-16.
    ISBN 9780135489680. Production blueprints: reasoning models, computer use, multimodal,
    fine-tuning, testing/monitoring/cost optimization. Rating n/a (new).
    https://www.amazon.com/Building-Agentic-Fine-Tuning-Optimization-Deployment/dp/0135489687

A6. **AI Agents and Applications: With LangChain, LangGraph, and MCP** — Roberto Infante.
    Manning, print pub 2026-02, 448pp. ISBN 9781633436541. Prompt eng, advanced RAG, agentic
    workflows w/ LangGraph, tool-based agents, multi-agent systems, MCP. Available via MEAP.
    Rating n/a. https://www.manning.com/books/ai-agents-and-applications

A7. **Build a Multi-Agent System (from Scratch)** — Val Andrei Fajardo. Manning, MEAP
    (early access, in progress mid-2026). Coordinating/delegating agent teams, MCP + A2A
    protocols. NOT YET FULLY PUBLISHED — mark as early-access. Rating n/a.
    https://www.manning.com/books/build-a-multi-agent-system-from-scratch

A8. **AI Agents: The Definitive Guide: Design, Deployment, and Evaluation for Production** —
    Nicole Koenigstein. O'Reilly. Listed pub ~Nov 2026 = FORTHCOMING / early-release chapters
    online now (id 0642572247775). ISBN 9798341666931. Production agents, orchestration on
    Ray/Kubernetes, multi-agent architectures/patterns. Rating n/a; FORTHCOMING — mark clearly.
    https://www.oreilly.com/library/view/ai-agents-the/0642572247775/

### (B) THEORY / BACKGROUND — pre-LLM classic MAS textbooks

B1. **Multiagent Systems** (2nd edition) — edited by Gerhard Weiss. MIT Press, 2013 (1st ed
    1999). 867pp, 31 contributors. Goodreads 3.74 (50 ratings). Broad DAI survey: distributed
    problem solving, learning, comms, negotiation. Theory reference; framework content dated.
    https://mitpress.mit.edu/9780262731317/multiagent-systems/
    https://www.goodreads.com/book/show/16248632-multiagent-systems

B2. **An Introduction to MultiAgent Systems** (2nd edition) — Michael Wooldridge. Wiley,
    2009-05. ISBN 9780470519462. Goodreads ~3.55 (paperback 3.57/53; AbeBooks cites 3.55/71).
    The standard undergrad MAS intro: agents, BDI, communication, cooperation, game theory.
    Readable; excellent conceptual grounding, zero LLM content.
    https://www.cs.ox.ac.uk/people/michael.wooldridge/pubs/imas/IMAS2e.html

B3. **Multiagent Systems: Algorithmic, Game-Theoretic, and Logical Foundations** — Yoav Shoham
    & Kevin Leyton-Brown. Cambridge University Press, 2008. ISBN 9780521899437. Goodreads 3.75
    (40 ratings, 2 reviews). Rigorous: game theory, mechanism design, auctions, social choice,
    logics of knowledge. Legal FREE PDF from authors. Deep theory; heavy math.
    https://www.goodreads.com/book/show/5241622-multiagent-systems

B4. **Reinforcement Learning: An Introduction** (2nd edition) — Richard S. Sutton & Andrew G.
    Barto. MIT Press, 2018. ISBN 9780262039246. Goodreads 4.54 (839 ratings, 87 reviews). The
    RL bible. Relevant to agents only for RL-based control / RLHF background; not about LLM
    multi-agent orchestration. Include as optional background. Free PDF from authors.
    https://www.goodreads.com/book/show/739791.Reinforcement_Learning

## Notes on staleness / honesty
- Pre-LLM (B) books: theory (game theory, BDI, mechanism design, coordination) is timeless and
  underpins A2A/negotiation patterns, BUT contain ZERO on transformers/LLMs/tool-calling. Buy
  for concepts, not implementation.
- (A) books are fresh (all 2025-2026) so framework churn risk is real: LangGraph hit v1.0
  Oct 2025; anything pinned to pre-1.0 APIs may drift. Patterns/architecture age better than
  code listings.
- Forthcoming/early-access flagged: A7 (Fajardo MEAP), A8 (Koenigstein ~Nov 2026). Ratings n/a
  for all books published after ~Sep 2025.

---

## HANDS-ON ENGINEERING BOOKS — VERIFIED (2026-07-10, second pass)

Focus: books an engineer actually builds from — agent loops, tool/function calling, RAG &
memory, prompt/context engineering, evaluation, production deployment. All confirmed real via
publisher + retailer + Goodreads. Ratings = Goodreads unless noted (consistent cross-title
metric; Amazon star counts hard to scrape reliably).

### Core LLM-application engineering (not agent-specific but foundational)
E1. **AI Engineering: Building Applications with Foundation Models** — Chip Huyen — O'Reilly,
    Jan 7 2025 (final), 532pp. Goodreads 4.35 / 1,061 (note: prior-pass fetch saw 4.38/1,226 —
    number is climbing). Most-read O'Reilly book of 2025. THE reference for eval, prompt eng,
    RAG, fine-tuning, inference optimization, agent chapter. Intermediate. Very current.
    https://www.oreilly.com/library/view/ai-engineering/9781098166298/ | rating https://www.goodreads.com/book/show/216848047-ai-engineering

E2. **Hands-On Large Language Models: Language Understanding and Generation** — Jay Alammar &
    Maarten Grootendorst — O'Reilly, Oct 15 2024 (final), 425pp. Goodreads 4.29 / 282. Highly
    visual; tokenizers, embeddings, semantic search, RAG, fine-tuning. Beginner->intermediate.
    Lighter on agents/production. https://www.oreilly.com/library/view/hands-on-large-language/9781098150952/ | rating https://www.goodreads.com/book/show/210408850-hands-on-large-language-models

E3. **Prompt Engineering for LLMs: The Art and Science of Building LLM-Based Applications** —
    John Berryman & Albert Ziegler (GitHub Copilot architects) — O'Reilly, Nov 4 2024 (final),
    471pp. Goodreads 3.83 / 93. Context assembly, few-shot, CoT, RAG, prompt strategy for real
    apps. Directly relevant to context engineering for agents. Intermediate.
    https://www.oreilly.com/library/view/prompt-engineering-for/9781098156145/ | rating https://www.goodreads.com/book/show/221244015-prompt-engineering-for-llms

E4. **LLM Engineer's Handbook: Master the art of engineering LLMs from concept to production** —
    Paul Iusztin & Maxime Labonne — Packt, Oct 22 2024 (final), ~522pp print (783 Kindle-equiv).
    Goodreads 3.88 / 69. End-to-end LLMOps: data pipelines, fine-tuning, RAG, deployment on AWS,
    monitoring. Intermediate->advanced; heavy MLOps flavor. https://www.packtpub.com/en-us/product/llm-engineers-handbook-9781836200062 | rating https://www.goodreads.com/en/book/show/216193554-llm-engineer-s-handbook

E5. **Building LLM Powered Applications: Create intelligent apps and agents with LLMs** —
    Valentina Alto — Packt, May 22 2024 (final), 342pp. Goodreads 3.62 / 34 (Amazon ~4.2).
    LangChain-centric intro to LLM apps + simple agents. Beginner->intermediate. Aging fastest
    (mid-2024, pre-LangGraph-1.0). https://www.packtpub.com/en-us/product/building-llm-powered-applications-9781835462317 | rating https://www.goodreads.com/book/show/201054993-building-llm-powered-applications

E6. **Building LLMs for Production: Enhancing LLM Abilities and Reliability with Prompting,
    Fine-Tuning, and RAG** — Louis-Francois Bouchard & Louie Peters (Towards AI, reputable
    self-pub) — May 21 2024, rev/updated Oct 2024, 463pp. Goodreads 4.09 / 93. Practical
    prompting + RAG + fine-tuning for production; LangChain/LlamaIndex. Intermediate.
    https://www.amazon.com/dp/B0D4FFPFW8 | rating https://www.goodreads.com/book/show/213731760-building-llms-for-production

### Agent-specific engineering
E7. **AI Agents in Action** — Micheal Lanham — Manning, Mar 25 2025 (final 1st ed), 344pp.
    Goodreads 3.12 / 73 (lowest of the batch — mixed reviews). Agent behavior patterns, OpenAI
    Assistants API, AutoGen, CrewAI, memory, planning, eval. 2nd Ed in MEAP adds MCP,
    containerized deploy, voice orchestration. https://www.manning.com/books/ai-agents-in-action | rating https://www.goodreads.com/en/book/show/221160748-ai-agents-in-action

E8. **Building Applications with AI Agents: Designing and Implementing Multiagent Systems** —
    Michael Albada — O'Reilly, Oct 21 2025 (final), 352pp. Goodreads 3.40 / 57. Agent core
    (tools/memory/orchestration), LangGraph, AutoGen, CrewAI, OpenAI Agents SDK, tool use,
    security, eval. Intermediate. Current. https://www.oreilly.com/library/view/building-applications-with/9781098176495/ | rating https://www.goodreads.com/book/show/230529414-building-applications-with-ai-agents

E9. **Building Agentic AI Systems: Create intelligent, autonomous AI agents that can reason,
    plan, and adapt** — Anjanava Biswas & Wrick Talukdar — Packt, Apr 21 2025 (final), 292pp.
    Goodreads 2.93 / 30 (low; small sample). Coordinator/worker/delegator patterns, multi-step
    planning, tool integration, trust/safety. Won 2025 Goody Business Book Award (Technology).
    https://www.packtpub.com/en-us/product/building-agentic-ai-systems-9781803238753 | rating https://www.goodreads.com/book/show/230153837-building-agentic-ai-systems

E10. **Building AI Agents with LLMs, RAG, and Knowledge Graphs: A practical guide to autonomous
     and modern AI agents** — Salvatore Raieli & Gabriele Iuculano — Packt, 2025 (final).
     Page count UNVERIFIED (~580). Ratings not yet meaningful. Distinctive angle: grounding
     agents in knowledge graphs + RAG. ISBN 9781835087060.
     https://www.packtpub.com/en-us/product/building-ai-agents-with-llms-rag-and-knowledge-graphs-9781835087060

### LangChain / framework-authored
E11. **Learning LangChain: Building AI and LLM Applications with LangChain and LangGraph** —
     Mayo Oshin & Nuno Campos (Campos = founding LangGraph engineer) — O'Reilly, Feb 2025
     (final), 296pp. Goodreads 3.79 / 53. RAG + LangGraph agent architecture, deploy, eval.
     Some reviewers: "doesn't add much over the docs." https://www.oreilly.com/library/view/learning-langchain/9781098167271/ | rating https://www.goodreads.com/book/show/220306097-learning-langchain

E12. **Generative AI with LangChain, Second Edition** — Ben Auffarth & Leonid Kuligin — Packt,
     May 23 2025 (final), ~468pp. 2nd-ed ratings limited; 1st-ed Goodreads 3.58 / 31. 2nd ed
     leans hard into multi-agent, LangGraph workflows, advanced RAG, testing/eval/deployment.
     Prototype->production emphasis. https://www.packtpub.com/en-us/product/generative-ai-with-langchain-9781837022014 | rating (1st ed) https://www.goodreads.com/book/show/185125672-generative-ai-with-langchain

### "Hyped but not real" check
- Every seed-list title resolved to a REAL published (or genuinely in-progress) book. No
  fabricated/hallucinated titles found.
- "AI Agents: The Definitive Guide" (Koenigstein, O'Reilly) is REAL but NOT a finished book —
  early-release chapters only, final ~late 2026. Flag as forthcoming.
- A pirate-scrape listing gives that title a garbage subtitle "(For Fdafg Fdsaf)", a 2027 date
  and bogus ISBN 9788341666895 — that's a bad scrape, not evidence the book is fake.

## Deliverable — DONE (final orchestrator build)
- index.html: rebuilt as ONE comprehensive tabbed dark dashboard, superseding the narrower
  agent drafts. 8 left-nav tabs: overview / hands-on engineering / multi-agent & orchestration /
  theory & background / compare all (sortable JS table, 23 rows) / reading paths (3 goal-based
  paths with step timelines) / gaps & non-books / method & sources. JetBrains Mono, OKLCH
  woodsy palette, light/dark toggle + no-flash script, responsive drawer <900px.
- README.md: rewritten as one unified survey summary.
- Verified anchor ratings directly: AI Engineering GR 4.38/1,226; Raschka "Build an LLM from
  Scratch" GR 4.60/354 (highest in survey); Hands-On LLMs GR 4.29/282.
- Cleaned up stray sub-agent folders (agent-book-gaps, book-ratings-survey) — not committed.

## Final book count: 24 verified (13 hands-on incl. foundations+agent+framework, 6 multi-agent,
## 4 theory; Albada cross-listed in both hands-on and multi-agent tabs).
## Key editorial calls
- Weighted recency heavily; flagged framework-named books as ~12-month consumables.
- Kept 4 pre-LLM theory books but labelled them theory/background ("zero LLM content").
- Flagged forthcoming (Koenigstein) + MEAP/early-access (Fajardo, Infante) explicitly.
- Surfaced honest "no book exists" gaps (MCP, evals, context eng, multi-agent-in-prod) with the
  best non-book resource for each (Anthropic essays, 12-factor agents, ReAct/Toolformer, etc.).
