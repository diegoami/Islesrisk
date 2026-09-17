# Malpaco — asset and dependency ledger

Provenance and licence for everything in this repository that someone else
wrote: images, fonts, shaders, sounds, and vendored code. Kept current from
the first asset, because the commercial question is still open
([DECISIONS.md](DECISIONS.md), "Commercial intent") and a licence that
cannot be reconstructed later is an art rewrite.

**Add a row in the same commit that adds the file.** Never "temporarily"
use something whose licence you have not checked.

## Vendored code

| What | Where | Version | Licence | Source |
|---|---|---|---|---|
| gdUnit4 | `addons/gdUnit4/` | 6.2.1 | MIT © 2023-2026 Mike Schulze | <https://github.com/godot-gdunit-labs/gdUnit4> |

gdUnit4 is committed rather than fetched so that a clean clone can run the
gates offline. Its own self-tests (`addons/gdUnit4/test/`) are removed to
keep the tree small; the licence file is kept.

## Art, fonts, audio

None yet. The art direction is deliberately procedural — shaders and
generated geometry rather than authored images (ARCHITECTURE.md, "Looking
good") — so this table should stay short. Fonts are the likeliest first
entry, and fonts are also the likeliest licence trap: check the EULA covers
embedding in a distributed binary before committing one.
