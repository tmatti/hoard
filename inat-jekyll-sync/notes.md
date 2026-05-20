# iNaturalist → Jekyll Auto-Posting — Investigation Notes

Started 2026-05-19.

## Goal

Automate posting iNaturalist observations from the user's account into a Jekyll
site hosted on GitHub Pages. A scheduled GitHub Action pulls new observations
daily and commits one Markdown post per run, gated by a successful `jekyll build`.

## Design (post /grill-me)

Settled during the grilling phase:

- **Storage:** Generated Markdown committed to the repo (not built dynamically).
- **Dedup:** `_data/inat_published.yml` — list of obs IDs already posted.
- **Cadence:** Daily run at 07:00 UTC; one post per run for new obs.
- **Filter:** All obs, no quality-grade filter.
- **Photos:** Hotlinked from iNat CDN at `medium` size, all photos as a gallery.
- **Location:** `place_guess` text only, anonymous API (no auth token).
- **Backfill:** Full historical backfill on first run, grouped by `observed_on` date.
- **Mutability:** Posts are snapshots — never re-synced.
- **Layout:** `_posts/` with `tags: [inaturalist]`.
- **Landing page:** Photo grid at `/observations/`.
- **Language:** Ruby, stdlib only.
- **Commit flow:** Direct push to `main` gated by `jekyll build`.

## Investigation plan

1. Confirm iNat API endpoints, fields, pagination behavior.
2. Sketch the Ruby sync script.
3. Sketch the GitHub Actions workflow.
4. Sketch Jekyll layout files (post + landing page).
5. Write installation/setup README.
6. Final dashboard `index.html`.

## API exploration

### Endpoint

`https://api.inaturalist.org/v1/observations` — documented at
https://api.inaturalist.org/v1/docs

Useful query params:

- `user_login=<username>` — filter to one user (no auth needed).
- `per_page=200` — max page size.
- `page=N` — pagination (also accepts `id_above` for keyset pagination).
- `order_by=observed_on` (or `created_at`), `order=asc|desc`.
- `id_above=<id>` / `id_below=<id>` — keyset pagination, more reliable than offset
  for large result sets.

### Rate limits

Per https://www.inaturalist.org/pages/api+recommended+practices:

- 100 requests/min, ~10k/day soft limit.
- They ask scripts to set a descriptive `User-Agent` so they can contact you.
- For our use: one user's history paginated 200/page. Even 10k obs = 50 requests.
  Fine.

### Response shape (relevant fields per observation)

```
{
  "id": 123456789,
  "uuid": "...",
  "observed_on": "2024-08-12",
  "observed_on_string": "2024-08-12 4:23 PM",
  "time_observed_at": "2024-08-12T23:23:00+00:00",
  "created_at": "2024-08-13T01:14:22+00:00",
  "updated_at": "2024-08-14T09:00:11+00:00",
  "uri": "https://www.inaturalist.org/observations/123456789",
  "description": "Found near the creek.",
  "place_guess": "Mount Tamalpais State Park, CA, USA",
  "geoprivacy": null,
  "quality_grade": "research",
  "taxon": {
    "id": 12345,
    "name": "Sceloporus occidentalis",
    "rank": "species",
    "preferred_common_name": "Western Fence Lizard",
    "iconic_taxon_name": "Reptilia"
  },
  "photos": [
    {
      "id": 999,
      "url": "https://inaturalist-open-data.s3.amazonaws.com/photos/999/square.jpg",
      "attribution": "..."
    }
  ],
  "tags": ["lizard", "creek"]
}
```

The `photos[].url` field comes back as the **square** thumbnail. To get other
sizes, swap the path segment: `square` → `small` / `medium` / `large` / `original`.

### Test request

Verified that the endpoint works without auth and returns the documented shape.
Used `kueda` (iNat co-founder, well-known prolific user) as a public test user.
Command saved in `scratch_curl.sh`.

## Ruby script design

Structure of `scripts/inat_sync.rb`:

1. Load config (username, paths) from `_config.yml` or env vars.
2. Load manifest from `_data/inat_published.yml`.
3. Fetch all observations for the user, paginated via `id_above`.
4. Filter out IDs already in the manifest.
5. Group new obs by `observed_on` date (for backfill mode) or by today's date
   (steady-state).
6. Render one Markdown post per group via ERB template.
7. Append new IDs to the manifest.
8. Print a summary; exit non-zero if anything failed.

Stdlib only: `net/http`, `json`, `yaml`, `erb`, `fileutils`, `optparse`, `date`.

Flags:
- `--dry-run` — don't write files.
- `--backfill` — group by `observed_on`, don't bail if pulling >1000 obs.
- `--user <login>` — override the configured username (handy for testing).

## GitHub Actions workflow

`.github/workflows/inat-sync.yml`:

1. `on.schedule: '0 7 * * *'` + `on.workflow_dispatch` for manual runs.
2. `permissions.contents: write` — needed to push back.
3. Steps:
   - Checkout
   - Setup Ruby (cached)
   - Run `scripts/inat_sync.rb` (writes new posts + manifest update)
   - If nothing changed: exit clean
   - Otherwise: `bundle exec jekyll build` to validate
   - Commit + push via `stefanzweifel/git-auto-commit-action` (or hand-rolled git
     commands using `github-actions[bot]` identity).

## Jekyll integration

- Post template: ERB → emits frontmatter (title, date, tags, hero photo URL) and
  body markdown.
- Landing page: `observations.md` at site root with a Liquid loop over
  `site.tags.inaturalist`, rendering a grid of `<a><img></a>` tiles using the
  hero photo URL stashed in each post's frontmatter.

## Open questions for after the investigation

- User's actual iNat username — `tmatti56` on iNat? Need to confirm before going
  live. Script uses a configurable login so it doesn't matter for the
  investigation.
- Whether the user's existing Jekyll site already has an `observations.md` or
  `/observations/` route that might collide. Investigation can't check this
  without access to the blog repo.
