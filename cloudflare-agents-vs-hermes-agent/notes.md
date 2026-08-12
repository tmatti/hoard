# Cloudflare Agents vs Nous Research Hermes Agent — comparison investigation

Date: 2026-08-11

## Goal
Fair, detailed comparison across 10 dimensions (state/memory, hosting, scaling,
real-time comms, durability, model flexibility, tooling, language/runtime,
portability, pricing). User supplied Cloudflare reference claims; verify Hermes
from its repo README/docs, spot-check Cloudflare claims against docs.

## Log

### Hermes Agent (github.com/NousResearch/hermes-agent, fetched 2026-08-11)
- Python 3.11, MIT, ~229k stars, default branch main. Topics reference openclaw/clawdbot/moltbot — has a first-class OpenClaw migration path (`hermes claw migrate`), so it's the same product category as OpenClaw: a self-hosted *personal* agent.
- Tagline: "The self-improving AI agent" / "the agent that grows with you". Differentiator = closed learning loop: autonomous skill creation after tasks, skills self-improve during use, memory nudges, FTS5 search over past sessions, Honcho dialectic user modeling. agentskills.io standard.
- **State**: all local under ~/.hermes — MEMORY.md (2,200-char cap) + USER.md (1,375-char cap) injected into system prompt; sessions in SQLite `state.db` with FTS5 (`session_search` tool); lineage tracking across compressions; atomic writes; profile-scoped isolation (multi-profile = separate HERMES_HOME + gateway PID). No external DB required. Optional external memory providers for team sync.
- **Hosting**: curl|bash installer (Linux/macOS/WSL2/Termux), native Windows PowerShell installer, Docker; runs on laptop, $5 VPS, GPU cluster. Desktop app (Electron) + Tauri bootstrap installer. Terminal *backends* for tool execution: local, Docker, SSH, Singularity/Apptainer, Modal, Daytona, Vercel Sandbox (Daytona/Modal = serverless hibernation, "costs nearly nothing when idle").
- **Scaling**: synchronous single-process agent loop (`AIAgent`), one gateway process with 25+ platform adapters; concurrency = multiple profiles/processes, manual. Subagent delegation (`delegate_task`) for parallelism within a task. No autoscaling, not multi-tenant.
- **Comms**: Telegram, Discord, Slack, WhatsApp, Signal, SMS, Email, BlueBubbles(iMessage), Teams, Matrix, Mattermost, IRC, LINE, QQ, WeChat/Weixin/WeCom, DingTalk, Feishu/Lark, Google Chat, SimpleX, ntfy, Home Assistant, webhooks. Streaming edits on many platforms; voice transcription + TTS replies. Cron with delivery to any platform.
- **Durability**: sessions survive restarts; delivery ledger records final responses durably + redelivery on crash. No mid-task durable execution — a crash kills the in-flight turn; you resume the conversation, not the step.
- **Models**: 100+ providers; OpenAI, Anthropic, Gemini/Vertex, xAI, DeepSeek, Qwen, Moonshot, Bedrock, Azure, Copilot, NIM, Groq, Together; local: Ollama (needs ≥64k ctx), vLLM, SGLang, llama.cpp, LM Studio; any OpenAI-compatible endpoint. `/model` switch, no code change.
- **Tools**: 40+ built-in: web_search/web_extract, x_search, browser_navigate/snapshot/vision, terminal/process/read_file/patch, execute_code, vision_analyze, image_generate, text_to_speech, memory, session_search, cronjob, todo/clarify/delegate_task, Home Assistant, MCP client. Toolsets to enable/disable per platform. Nous Tool Gateway bundles search/imagegen/TTS/cloud-browser under Portal sub.
- **Pricing**: software free (MIT). Costs = your compute + model API. Nous Portal: free tier ($0, free-model catalog, 50 RPM/500K TPM), Plus $20, Super $100, Ultra $200/mo w/ bonus credits; includes 300+ models + Tool Gateway.

### Cloudflare Agents (developers.cloudflare.com/agents, fetched 2026-08-11)
- Verified docs language: "durable identity, local SQL storage, real-time connections, scheduled work, and recoverable execution"; channels chat/voice/email/Slack/webhooks + WebSockets; "scaling to tens of millions of instances"; built-in browser automation, sandboxed code exec, AI Search, MCP, payments, Code Mode; Workers AI default in starter, external providers supported; logs/metrics/traces integrated. Matches user's reference list. Cloudflare MCP connector in this session was invalidated — used WebFetch instead.

### Framing conclusion
Not direct competitors. CF Agents = developer *platform/framework* for building multi-tenant agent products (agent-session-per-Durable-Object). Hermes = finished self-hosted *personal agent application* (single human, many channels, learning loop). Overlap zone: solo dev building "an agent that talks to me on Slack/Telegram and does tasks" could use either.
