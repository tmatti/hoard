# AI Agent / LLM Books — Aggregate Ratings Survey

Accessed: 2026-07-10

## Goal
Find Amazon + Goodreads ratings for a set of books about building LLM apps / AI agents.
Rules: no fabrication. "NOT FOUND" if unavailable. Verify each book exists.

## Books
1. AI Engineering: Building Applications with Foundation Models — Chip Huyen (O'Reilly, 2025)
2. Hands-On Large Language Models — Jay Alammar & Maarten Grootendorst (O'Reilly, 2024)
3. LLM Engineer's Handbook — Paul Iusztin & Maxime Labonne (Packt, 2024)
4. Building LLM Powered Applications — Valentina Alto (Packt, 2024)
5. Designing Machine Learning Systems — Chip Huyen (O'Reilly, 2022)
6. AI Agents books 2024-2026 (find real ones)

## Progress log

### Method
- Goodreads: WebFetch of live book pages gave exact avg rating + ratings count + reviews count. PRIMARY, accessed 2026-07-10.
- Amazon: product pages return only <head> (JS-rendered ratings not in static HTML); product-reviews path returns 503. Search snippets do NOT expose Amazon rating counts. => Amazon rating COUNTS = NOT FOUND for all.
- Amazon STAR ratings (no counts) available only from a SECONDARY aggregator: github.com/Jason2Brownlee/awesome-llm-books (per-book .md files) and one search snippet. Marked secondary/unverified; may be stale.

### Findings (Goodreads = PRIMARY live, 2026-07-10)

1. AI Engineering (Chip Huyen, O'Reilly 2025, ISBN 9781098166304 / 1098166302)
   - Goodreads (id 216848047): 4.38 avg, 1,226 ratings, 153 reviews. Distribution 53/34/10/1/<1.
   - Amazon (secondary, awesome-llm-books): 4.7 stars, count NOT FOUND.
   - Verified: exists. huyenchip.com/books confirms.

2. Hands-On Large Language Models (Alammar & Grootendorst, O'Reilly 2024, ISBN 9781098150969)
   - Goodreads (id 210408850): 4.29 avg, 282 ratings, 32 reviews. (note: alt edition id 219153362 exists)
   - Amazon (secondary): 4.7 stars, count NOT FOUND.

3. LLM Engineer's Handbook (Iusztin & Labonne, Packt 2024, ISBN 9781836200079)
   - Goodreads (id 216193554): 3.88 avg, 69 ratings, 9 reviews.
   - Amazon (secondary): 4.6 stars, count NOT FOUND.

4. Building LLM Powered Applications (Valentina Alto, Packt 2024, ISBN 9781835462317)
   - Goodreads (id 201054993): 3.58 avg, 36 ratings, 8 reviews.
   - Amazon (secondary): 4.2 stars, count NOT FOUND.

5. Designing Machine Learning Systems (Chip Huyen, O'Reilly 2022, ISBN 9781098107963)
   - Goodreads (id 60715378): 4.44 avg, 1,152 ratings, 116 reviews.
   - Amazon (secondary): 4.7 stars, count NOT FOUND.

6. AI Agents books (real, 2024-2026):
   a. AI Agents in Action — Micheal Lanham (Manning, 2025, ISBN 9781633436343)
      - Goodreads (id 221160748): 3.10 avg, 78 ratings, 18 reviews.
      - Amazon (search snippet, secondary): 4.1 stars, count NOT FOUND.
      - Note: 2nd Edition exists (ISBN 9781633434530).
   b. Learning LangChain — Mayo Oshin & Nuno Campos (O'Reilly, Mar 25 2025, ISBN 9781098167288)
      - Goodreads (id 220306097): 3.79 avg, 53 ratings, 12 reviews.
      - Amazon: NOT FOUND.
   c. Building Agentic AI Systems — Anjanava Biswas & Wrick Talukdar (Packt, Apr 21 2025, ISBN 9781803238753)
      - Goodreads (id 230153837): 2.93 avg, 30 ratings, 6 reviews.
      - Amazon: NOT FOUND.
   - Also seen (not deep-dived): "Building Agentic AI" (Sinan Ozdemir, GR 241823059), "Agentic AI Engineering" (Yi Zhou, GR 241106813) — very new, few ratings.

### Caveats
- Goodreads numbers move daily; snapshot = 2026-07-10.
- Amazon counts genuinely NOT FOUND (blocked). Amazon star figures are secondary-source, treat as approximate.

</content>
</invoke>
<invoke name="WebSearch">
<parameter name="query">Chip Huyen "AI Engineering" Building Applications Foundation Models Goodreads rating