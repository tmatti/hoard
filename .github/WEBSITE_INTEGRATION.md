# Prompt: render hoard projects on the personal website

Feed the prompt below to a coding agent working on the personal-website repo. It
documents the contract published by this repo's `publish-r2.yml` workflow.

---

I have a Cloudflare R2 bucket, exposed on a public custom domain, that holds
self-contained HTML artifacts published automatically from my public
`tmatti/hoard` GitHub repo. I want this website to render them as a "Projects"
list, with each artifact viewable as its own page.

## The bucket contract

Base URL: `https://<BUCKET_PUBLIC_DOMAIN>/hoard/` (I will supply the real
domain; keep it in a single config value, not scattered through the code).

1. **`hoard/manifest.json`** — the list of projects. Served with
   `Cache-Control: no-cache`. Shape:

   ```json
   {
     "generated_at": "2026-07-11T18:04:00Z",
     "projects": [
       {
         "slug": "ai-agent-books",
         "title": "Books for Building AI Agents — A Survey (mid-2026)",
         "created": "2026-07-10",
         "updated": "2026-07-10"
       }
     ]
   }
   ```

   `projects` is sorted newest-first by `created`. Titles are plain decoded
   text (may contain Unicode like `→` and `—`). There are no descriptions.

2. **`hoard/<slug>/index.html`** — one fully self-contained HTML page per
   project (inline CSS/JS; only external dependency is Google Fonts). Served
   with `Content-Type: text/html` and `Cache-Control: public, max-age=300`.
   New projects appear automatically when the manifest updates; do not
   hardcode slugs anywhere.

## What to build

1. A **projects index page** on the site that fetches `hoard/manifest.json`
   and renders one entry per project: title, created date (and updated date
   when it differs), linking to the artifact page. Handle fetch failure
   gracefully (show a quiet error state, don't break the page).
2. A way to **view each artifact**. Prefer linking directly to
   `hoard/<slug>/index.html` on the bucket domain (the pages are standalone
   documents with their own styling and light/dark handling). Only embed or
   proxy them if direct links clash with how this site is architected — ask
   me before choosing an iframe/proxy approach.
3. Fetching may happen client-side or at build/request time, whichever fits
   this site's stack — but if it's at build time, note in your summary that
   new hoard pushes won't appear until the next site build, and tell me what
   rebuild hook I'd need.

## Constraints

- The manifest is the single source of truth; never enumerate the bucket and
  never hardcode the project list.
- If fetching client-side from a different origin than the bucket domain,
  CORS must allow this site's origin — that's configured on the R2 bucket
  (Cloudflare dashboard), not in this repo. Tell me the exact origin string
  you need allowed.
- Don't store any Cloudflare credentials in this repo; everything published
  is world-readable over plain HTTPS.
