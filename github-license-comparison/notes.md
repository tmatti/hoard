# GitHub Software License Options — Comparison

## Goal
Make an interactive diagram/report comparing the pros and cons of each software
license option GitHub offers in its "Choose a license" / repository license picker.

## Source of the list
When you create a repo on GitHub (or click "Add license"), GitHub surfaces the
licenses curated at https://choosealicense.com (an official GitHub project).
The picker's full list (the 13 software/public-domain options) is:

1. MIT License
2. Apache License 2.0
3. GNU GPLv3 (GNU General Public License v3.0)
4. GNU GPLv2 (GNU General Public License v2.0)
5. GNU AGPLv3 (GNU Affero General Public License v3.0)
6. GNU LGPLv3 (GNU Lesser General Public License v3.0)
7. Mozilla Public License 2.0 (MPL-2.0)
8. BSD 2-Clause "Simplified" License
9. BSD 3-Clause "New"/"Revised" License
10. Boost Software License 1.0 (BSL-1.0)
11. The Unlicense
12. Eclipse Public License 2.0 (EPL-2.0)
13. Creative Commons Zero v1.0 Universal (CC0-1.0) — public-domain dedication

(GitHub also lists CC-BY-4.0 for non-software/content; I'm focusing on the
software-relevant ones above, mentioning CC0 as the public-domain option.)

## Mental model: three families
- **Permissive** — do almost anything, just keep the notice. (MIT, Apache-2.0,
  BSD-2/3, BSL-1.0)
- **Copyleft** — derivatives must stay under the same/compatible license and ship
  source. Weak/file-level (MPL, LGPL, EPL) vs strong (GPL) vs network/strong
  (AGPL).
- **Public domain / no-rights-reserved** — Unlicense, CC0.

## Key axes for comparison (from choosealicense.com permissions/conditions/limitations)
- Permissions: commercial use, modification, distribution, private use, patent grant
- Conditions: license+copyright notice, state changes, disclose source, same license
- Limitations: liability, warranty, trademark use
- Patent grant: explicit (Apache, GPLv3, AGPL, LGPLv3, MPL, EPL, BSL) vs none/implicit (MIT, BSD-2/3, GPLv2, Unlicense, CC0 explicitly excludes patents)
- Copyleft scope: none / file-level / library-boundary / whole-work / network

## Notable gotchas worth surfacing
- **MIT/BSD-2** = simplest, but no explicit patent grant.
- **Apache-2.0** = permissive + explicit patent grant + patent retaliation; NOT
  compatible with GPLv2 (but is with GPLv3).
- **GPLv2** has no explicit patent clause and no "or later" by itself; famous for
  the Linux kernel (GPLv2-only).
- **GPLv3** added patent grant + anti-tivoization + anti-DRM clauses.
- **AGPLv3** closes the "SaaS loophole": running modified code over a network
  counts as distribution → must offer source to users. Many companies ban AGPL
  internally (e.g., Google).
- **LGPLv3** = use as a library (dynamic link) without copylefting your app, but
  modifications to the library itself stay LGPL; user must be able to relink.
- **MPL-2.0** = file-level copyleft; great middle ground, GPL-compatible.
- **EPL-2.0** = file/module copyleft, business-friendly, common in Java/Eclipse.
- **BSL-1.0** = permissive, no notice required for binary/compiled distribution
  (popular in C++ / Boost world).
- **Unlicense / CC0** = public domain. CC0 explicitly does NOT grant patent or
  trademark rights; some orgs distrust Unlicense's legal robustness.

## Deliverable
- index.html: tabbed dark dashboard (tabs on left), JetBrains Mono, woodsy
  green/brown OKLCH palette per DESIGN.md. Tabs:
  1. Overview — the picker + 3 families + how to choose
  2. License Families — the spectrum diagram (permissive → copyleft)
  3. Comparison Matrix — all 13 across permissions/conditions/limitations
  4. Pros & Cons — per-license cards
  5. Decision Guide — pick-a-license flow
- Light/dark toggle, no-flash inline script, localStorage persistence.

## Disclaimer
Educational summary, not legal advice. Authoritative text: choosealicense.com
and the SPDX license list.
