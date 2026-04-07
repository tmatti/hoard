# ActiveRecord Cheat Sheet - Work Notes

## 2026-04-07

### Goal
Build an advanced ActiveRecord cheat sheet as an interactive HTML dashboard.
Target audience: experienced Rails devs who just need a quick reminder.

### Approach
- Single `index.html` file, self-contained
- Tabbed dashboard layout, dark mode
- highlight.js via CDN for Ruby syntax highlighting
- Copy-to-clipboard on code blocks
- Sections: Querying, Associations, Eager Loading, Scopes, Callbacks, Validations, Transactions, Performance & Gotchas, Migrations

### Key content decisions
- Performance & Gotchas is the most important tab — led with it (second tab after Querying)
- Included N+1 patterns, includes vs joins distinction, count/size/length trap, destroy vs delete, default_scope hazards, strict_loading, batch iteration
- Eager loading tab goes deep on the 4-way preload/includes/eager_load/joins distinction
- Skipped beginner explanations (what is a model, what is a migration, etc.)
