# Research Notes: Gaps in the Book Market for LLM Agent Engineers (mid-2026)

Goal: Identify topics where engineers say NO good BOOK exists, and the best resource is non-book (essay, paper, docs, course, repo, blog).

## Research log

Starting research 2026-07-10.

## Confirmed canonical resources (verified via search)

- Anthropic "Building Effective Agents" — https://www.anthropic.com/research/building-effective-agents — pub Dec 19/20 2024. Thesis: most successful implementations use simple, composable patterns NOT complex frameworks; distinguishes workflows (predefined code paths) vs agents (LLM dynamically directs). HN discussion id=42470541. Simon Willison writeup 2024/Dec/20.
- 12-factor agents — https://github.com/humanlayer/12-factor-agents — by HumanLayer. "shadcn for AI agents", principles for reliable LLM apps in production. HN id=43699271. create-12-factor-agent CLI. Also https://www.humanlayer.dev/12-factor-agents
- ReAct paper (Yao et al.) — https://arxiv.org/abs/2210.03629 — posted Oct 6 2022, ICLR 2023. Interleaves reasoning traces + actions. Code github.com/ysymyth/ReAct
- Toolformer (Schick et al.) — https://arxiv.org/abs/2302.04761 — Feb 9 2023. LMs teach themselves to use tools/APIs self-supervised.
- OpenAI "A Practical Guide to Building Agents" PDF — https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf — landing: https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/ . Covers use cases, model selection, tool design, guardrails, multi-agent, orchestration. (~34pp, 2025)
- Google/Kaggle "Agents" whitepaper + "Agents Companion" — https://www.kaggle.com/whitepaper-agent-companion ; Intro to Agents 42pp; part of 5-Day Gen AI Intensive (1.5M learners). 
- Chip Huyen "Agents" post — https://huyenchip.com/2025/01/07/agents.html — Jan 7 2025, adapted from AI Engineering (2025) book. Also genai-platform post https://huyenchip.com/2024/07/25/genai-platform.html
- Hamel Husain "Your AI Product Needs Evals" — https://hamel.dev/blog/posts/evals/ — Mar 29 2024. Also LLM-as-judge https://hamel.dev/blog/posts/llm-judge/
- MCP spec — https://modelcontextprotocol.io/specification/2025-11-25 ; repo github.com/modelcontextprotocol/modelcontextprotocol
- Anthropic "Effective context engineering for AI agents" — https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents — Sep 29 2025 (w/ Sonnet 4.5). Concept: context rot.
- LangChain "Context Engineering for Agents" — https://www.langchain.com/blog/context-engineering-for-agents
- Anthropic Engineering hub — https://www.anthropic.com/engineering (multi-agent research system, harnesses for long-running agents)
- DeepLearning.AI: Agentic AI (Andrew Ng) https://www.deeplearning.ai/courses/agentic-ai ; AI Agents in LangGraph (Harrison Chase) ; AI Agentic Design Patterns with AutoGen ; Multi AI Agent Systems with CrewAI
- Latent Space https://www.latent.space/ ; Simon Willison https://simonwillison.net/ ; Eugene Yan https://eugeneyan.com/

## More Anthropic Engineering posts found (all cited over books)
- "Demystifying evals for AI agents" — https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- "Writing effective tools for AI agents" — https://www.anthropic.com/engineering/writing-tools-for-agents
- "Effective harnesses for long-running agents" — https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Anthropic multi-agent research system — https://www.anthropic.com/engineering/multi-agent-research-system (Jun 13 2025; 90.2% > single agent; ~15x tokens)

## Simon Willison security work (the security/guardrails "book"-substitute)
- "The lethal trifecta for AI agents" (private data + untrusted content + external comms) — https://simonwillison.net/series/prompt-injection/ ; substack https://simonw.substack.com/p/the-lethal-trifecta-for-ai-agents . Dual-LLM pattern. OWASP LLM Prompt Injection Prevention cheat sheet also cited.

## Prompt caching / cost (docs are source of truth, no book)
- Anthropic prompt caching docs: cache_control ephemeral, 90% discount on cached tokens, min 1024 tokens, 5-min/1-hr TTL. Provider docs are the reference.

## Framework docs = "real source of truth" (canonical URLs)
- LangGraph — https://github.com/langchain-ai/langgraph ; docs https://docs.langchain.com/oss/python/langgraph ; LangChain Academy free course
- OpenAI Agents SDK — https://openai.github.io/openai-agents-python/ (vendor-native, guardrails in <100 LOC)
- CrewAI — https://docs.crewai.com/ (role/task crews)
- AutoGen (Microsoft) — reached 1.0 GA Feb 2026; https://microsoft.github.io/autogen/
- LlamaIndex — https://docs.llamaindex.ai/ (retrieval/doc intelligence + agents)
- MCP spec — https://modelcontextprotocol.io/ (Anthropic, Nov 2024; created by dsp + jspahrsummers)

## Community sentiment (VERIFIED quotes)
Ask HN: "Learning resources for building AI agents?" — https://news.ycombinator.com/item?id=47637083 (fetched):
- anilgulecha: "The best way to learn to build an agent is to learn and use pi.dev. The homepage is a masterclass of explaining the main loop with 4 tools"
- stochtinkerer: "Just start building my man. Would highly advise keeping it minimal, just use OpenAI Agents SDK"
- adi_kurian: "Text in, text out. It's all a bunch of prompts. Use the APIs directly and avoid as many abstraction layers"
- tfun: recommends mastra.ai docs; tabs_or_spaces: "move from theory into actually building"
- Recurring theme: learn by building + framework docs, not formal materials/books.
Other Ask HN: id=44173684 (agents for software dev), id=44450160 ("What to build instead of AI agents").

## NUANCE: books DO now exist (2025-2026), but not for the fast-moving edges
- Chip Huyen, "AI Engineering" (O'Reilly, 2025) — most-cited book; covers evals, agents, RAG.
- Jay Alammar, "Hands-On Large Language Models" (O'Reilly 2024).
- "LLM Engineer's Handbook" (Packt 2024) — LLMOps pipeline.
- "AI Agents in Action" 2nd ed (Manning) — covers MCP.
- Mastra "Principles of Building AI Agents" (free) — 34 ch incl MCP, evals, observability.
- BUT: reviewers/practitioners note these lag the primary sources; for MCP, evals, context engineering, security, multi-agent-in-prod, prompt caching, the go-to remains docs/papers/essays because books are outdated on arrival.

## GAP TABLE (topic | best non-book | url | why)
1. Agent design patterns / when-to-use-agents -> Anthropic Building Effective Agents (anthropic.com/research/building-effective-agents) — cited as THE reference; predates most books.
2. Production reliability / engineering discipline -> 12-factor agents (github.com/humanlayer/12-factor-agents) — "shadcn for agents".
3. MCP -> modelcontextprotocol.io spec — protocol too new + versioned (2025-11-25); books can't track it.
4. Agent evals -> Hamel Husain hamel.dev/blog/posts/evals + Anthropic Demystifying evals — evals blog is canonical.
5. Context engineering -> Anthropic effective-context-engineering + LangChain blog — coined 2025, no book.
6. Multi-agent orchestration in production -> Anthropic multi-agent-research-system + LangGraph docs.
7. Guardrails / security (prompt injection) -> Simon Willison lethal trifecta + OWASP cheat sheet — attack landscape shifts monthly.
8. Observability / tracing -> LangSmith/Langfuse/Braintrust docs + vendor guides — tooling-specific, no book.
9. Cost optimization / prompt caching -> provider docs (Anthropic/OpenAI caching) — pricing mechanics change.
10. Foundational patterns/theory -> ReAct (arxiv 2210.03629), Toolformer (arxiv 2302.04761) — papers are the primary source.
11. Vendor playbooks -> OpenAI Practical Guide PDF + Google/Kaggle Agents Companion whitepaper.
12. Staying current -> Latent Space, Simon Willison, Eugene Yan, DeepLearning.AI short courses.

