# Hoard

This is a repo where I hoard tutorials, research, and other projects carried out by an LLM. Each top-level directory is a distinct investigation I had an agent (usually Claude, sometimes GPT) run autonomously.

Back in the day when I wanted to learn a new technology, I would find a tutorial. They were great, but always very generic, and I would have to do extra work to apply the tech to my project. Now I just have the agent generate a tutorial or research report with the exact context my situation demands.

The finished reports are published to Cloudflare R2 and referenced by my personal website, which renders the collection as a browsable project list (see [How it's deployed](#how-its-deployed)).

## What's in each folder

Every investigation follows the same conventions (see [AGENTS.md](AGENTS.md)):

- `notes.md` — a running log of what the agent tried and learned along the way
- `index.html` — the final deliverable: a self-contained interactive report (tabbed dashboard, dark mode, styled per [DESIGN.md](DESIGN.md))
- Any code the agent wrote, or diffs against repos it modified — but never full copies of fetched code

## How it's deployed

Pushes to `master` trigger the [Publish artifacts to R2](.github/workflows/publish-r2.yml) GitHub Action, which:

1. Runs [build_staging.py](.github/scripts/build_staging.py) to find every top-level folder containing an `index.html`, stage each one as `<slug>/index.html`, and generate a `manifest.json` listing every project with its title (from the page's `<title>`) and created/updated dates (from git history).
2. Mirrors the staged pages into a dedicated Cloudflare R2 bucket with `rclone sync`, then uploads `manifest.json` last so pages always exist before the list that references them updates.

My personal site fetches `manifest.json` client-side and renders the project list from it, linking through to each report served straight from the bucket.

Credentials live in repository secrets (`R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ACCOUNT_ID`, `R2_BUCKET`), backed by an R2 API token scoped to that one bucket with object read/write only — nothing account-identifying is hardcoded in this public repo.
