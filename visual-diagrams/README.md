# Prompt

Write me up a tutorial on generating visual documentation for features i implement. I want to learn more about generating diagrams to better communicate my code

Context diagrams for high level system overview 

Component diagrams for internal views of classes, modules, dependencies 

c4 diagrams? 

Static diagrams 

Runtime diagrams for event storming

How to best represent asynchronous operations like sidekiq jobs in rails etc 

How I can configure my rails apps to automatically regenerate diagrams when code changes 

I like mermaid but I am open to other formats 

Etc

# Output
The tutorial covers all 10 topics you asked about with working diagram code throughout:

**What's inside:**

- **C4 Model** — all four levels explained, with actual Mermaid and PlantUML syntax for L1 (context) and L2 (container) diagrams
- **Context diagrams** — both C4-flavored and plain flowchart variants, with the key rules for what to include
- **Component diagrams** — class diagrams, module dependency graphs, and how to auto-generate them with `railroady`
- **Static diagrams** — ER diagrams with `erDiagram`, state machines for AASM/state_machines (with a full Order lifecycle example)
- **Runtime / Event Storming** — sequence diagrams with proper `alt`/`else` branching, and an event storming flowchart with the sticky-note color coding convention
- **Async / Sidekiq** — the most nuanced section: dashed arrows for deferred ops, job dependency DAGs, dead letter queues, scheduled cron jobs, and the enqueue-vs-execute temporal split
- **Auto-generation** — rake tasks that hook into `db:migrate`, a Guard integration for file watching, and a GitHub Actions workflow that auto-commits regenerated diagrams on schema changes
- **Workflow** — a concrete PR-by-PR process and a recommended `docs/diagrams/` directory structure

The Mermaid examples are all copy-pasteable into any GitHub markdown file and will render immediately.

[Open Tutorial](visual-documentation-tutorial.html)
