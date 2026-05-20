# inat-jekyll-sync

Automate posting iNaturalist observations into a Jekyll blog hosted on GitHub
Pages. A scheduled GitHub Action pulls new observations daily, renders one
Markdown post per run, and pushes to `main` only if `jekyll build` succeeds.

## What this folder contains

This is an **investigation deliverable** — design, code, and docs. To use it,
copy the files into your real Jekyll blog repo at the paths shown below.

| File in this folder              | Goes to (in your blog repo)             |
| -------------------------------- | --------------------------------------- |
| `scripts/inat_sync.rb`           | `scripts/inat_sync.rb`                  |
| `workflows/inat-sync.yml`        | `.github/workflows/inat-sync.yml`       |
| `jekyll/observations.html`       | `observations.html` (site root)         |
| `scripts/test_renderer.rb`       | (optional) `scripts/test_renderer.rb`   |
| `scripts/fixture_obs.json`       | (optional) `scripts/fixture_obs.json`   |

The Action also expects:

- An empty `_data/inat_published.yml` (or no file — the script will create one).
- A repo variable named `INAT_USER` set to your iNaturalist `user_login`.
- `inat_user` set in `_config.yml` (only used by the landing-page template).

## How it works

1. **Daily cron at 07:00 UTC** (also `workflow_dispatch` for manual runs).
2. Ruby script `scripts/inat_sync.rb`:
   - Reads `_data/inat_published.yml` — the manifest of obs IDs already posted.
   - Pages through `GET /v1/observations?user_login=<you>` via keyset
     pagination (`id_above`).
   - Skips IDs already in the manifest.
   - **Backfill mode** (first run, `--backfill`): groups remaining obs by
     `observed_on` date, writes one post per date.
   - **Steady-state mode** (no flag): writes one post containing all newly
     discovered obs, dated today.
   - Renders posts via ERB into `_posts/YYYY-MM-DD-observations-<slug>-<hash>.md`.
   - Appends new IDs to the manifest.
3. The Action then runs `bundle exec jekyll build --strict_front_matter`. If
   the build fails, nothing is committed.
4. On success, the Action commits `_posts/` and `_data/inat_published.yml`,
   pushes to `main`, GH Pages rebuilds.

## First-run setup

1. Copy files into your blog repo (paths above).
2. In your blog repo settings → Variables → Actions, add `INAT_USER` =
   your iNaturalist login (e.g. `tmatti56`).
3. Add to `_config.yml`:

   ```yaml
   inat_user: tmatti56
   ```

4. Manually trigger the workflow once with `backfill: true` to ingest your
   existing iNaturalist history. This walks all observations and writes one
   post per date observed. Review the resulting commit, then merge / accept.
5. Daily cron takes over from there.

## Local testing

```sh
# Smoke-test the renderer against a captured API fixture
ruby scripts/test_renderer.rb

# Dry-run against the live API
ruby scripts/inat_sync.rb --user kueda --dry-run

# Render against a real user, into a sandbox directory
ruby scripts/inat_sync.rb --user kueda --backfill \
  --posts-dir /tmp/_posts \
  --manifest /tmp/_data/inat_published.yml
```

## Design decisions

See [notes.md](notes.md) for the full investigation log, including the
question-by-question design rationale from the planning phase. Highlights:

- **Markdown is committed**, not built dynamically. Posts become permanent
  artifacts, editable by hand, surviving iNat changes.
- **Manifest-based dedup** (not date-based). Safe against backdated uploads,
  hand-edits, and partial failures.
- **Anonymous API** — no secrets, iNat's privacy rules apply automatically.
- **Hotlinked photos** at `medium` size. Zero repo bloat.
- **Snapshot posts** — never re-synced after commit. iNat is the live source.
- **Tag-based section** (`tags: [inaturalist]`) rather than a Jekyll
  collection, per user preference.

## API notes

- Endpoint: `https://api.inaturalist.org/v1/observations`
- Rate limit: ~100 req/min, ~10k/day. We're well under both.
- iNat asks scripts to identify themselves via `User-Agent`. The script
  includes one — edit `USER_AGENT` in `scripts/inat_sync.rb` to point to
  your repo.

## Failure handling

- Workflow failures email the repo admin by default (no extra setup).
- Concurrency group prevents overlapping runs.
- If `jekyll build` fails after rendering, the workflow exits non-zero and
  nothing is committed. The next day's run will see the same observations as
  "new" (because the manifest didn't update) and retry.
- iNat API outages cause a non-success status; the script aborts before
  modifying anything.
