## Design Context

### Aesthetic Direction
- **Visual tone**: Subtle terminal. JetBrains Mono throughout (explicit user choice). Restrained `$` / `~/` accents in nav and post metadata. No blinking cursors, no ASCII box frames. Reads like a blog, not a terminal emulator.
- **Color palette**: Woodsy greens (`--accent`: forest green) and warm browns (`--warm`: walnut/oak). Parchment light background, deep loam dark background. All neutrals tinted toward earthy warm hues using OKLCH.
- **Theme**: Both light and dark from day one. System preference respected on first visit; manual toggle remembers preference in localStorage. No flash on load.
- **Anti-references**: Generic developer blogs (neon-on-dark, sans-serif everything, cards everywhere), generic nature/outdoors blogs (earthy sepia tones with no personality).

### Design Principles
- **Terminal as aesthetic, not gimmick**: Use monospace, `$` prompts, and `~/path` accents as flavoring — never let them distract from content.
- **Restraint over richness**: The site should feel considered, not decorated. Whitespace and type rhythm do the heavy lifting.
- **Woodsy palette, always**: Any new colors must harmonize with the forest green accent and warm brown palette. No blues, no purples, no neon.
- **Tag-first navigation**: Categories/tags are the primary discovery mechanism. Any new content type should get tagged.

### Technical Context
- JetBrains Mono (Google Fonts CDN)
- OKLCH CSS custom properties for all colors
- Sidebar layout: 260px fixed on desktop, slide-in drawer on mobile (<900px)
- Light/dark toggle: `[data-theme="dark"]` on `<html>`, localStorage persistence, no-flash inline script in `<head>`
