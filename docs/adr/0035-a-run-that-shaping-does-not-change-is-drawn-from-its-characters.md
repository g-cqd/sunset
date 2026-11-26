---
status: accepted
date: 2026-11-15
---

# 0035 — A run that shaping does not change is drawn from its characters

Amends ADR-0032 (runs are shaped as one piece). It keeps its decisions and adds one; nothing of it is withdrawn.

## What changed the decision

ADR-0032 left "run shaping costs more than the per-cell path; not benchmarked; the default is off". The default became on
(`font.ligatures`), and a review of the running app (2026-11-15, kept in `docs/research`) found 110 MB of glyph bitmaps in six
terminals. Probed here (`Benchmarks/Probes/GlyphProbe`, release, a 120 x 40 screen scrolling 4,000 lines that look like a
log, Menlo and Maple Mono at 28 px):

| | per new line, p50 | bitmaps held after 4,000 lines |
| --- | --- | --- |
| ligatures off | 3.7 µs | 37, 20 KB |
| ligatures on, before | 60 µs (Menlo), 86 µs (Maple) | 13,521, **97 MB** and **108 MB** |

Every distinct word was shaped, rasterised and kept as a bitmap as wide as the word, although in almost all of them
shaping changes nothing: the word's bitmap was its characters' bitmaps side by side.

## Decision

- **The glyph seam can say that shaping changes nothing in a run**: `GlyphSource.runIsPlain`. True only when the run's
  bitmap would be its characters' bitmaps side by side, pixel for pixel; false when in doubt, and by default.
- **The renderer draws such a run from its characters' own glyphs** and makes no bitmap of it. The answer is remembered
  with the run (the run cache), so a run is asked about once.
- **The CoreText source answers** by shaping the run once and checking that each character is one glyph of the font
  itself, the glyph it has alone (shaped alone, so that a feature such as a slashed zero is counted in), in order, with its
  ink inside its cell. The last condition is what makes it exact: a glyph is drawn at the left of its cell either way, but
  ink that leaves the cell shows in a run's bitmap and is cut in a character's. A ligature, a contextual alternate, a glyph
  from a fallback font and a character outside the basic plane are not plain.
- **A run of printable ASCII made only of a style's safe bytes is not shaped at all** (the ASCII fast path, t241): it is
  plain without asking CoreText. A byte is safe when its glyph alone is the font's own (`cmap`) glyph and keeps to its
  cell, and no substitution could change it in any run made only of safe bytes. That last part is read from the font's
  `GSUB` (OpenType 1.9.1: every script and language system, required features, FeatureVariations alternates, extension
  lookups, types 1–6 and 8) or `morx` (Apple TrueType Reference Manual: chains v2/v3, the subtables on by default or by a
  feature setting, noncontextual and state-table subtables walked from both start states) by `SubstitutionReach`. Each
  way a rule could fire on safe glyphs takes one of its glyphs out of the set (a punctuation glyph before a letter or
  digit), until no rule can fire. Features off unless asked (`dlig`, `ssNN`, `cvNN`, `zero`, ...) count only when the
  configuration asks for them; `liga`, `clig` and `calt` stop counting when it turns them off. A table that does not read
  in full (malformed, an unknown format, over 65,536 firings or 512 states), and a font with the older `mort`, has no
  safe byte.
- **The glyph table is also bounded by its bytes** (16 MB a renderer), not only by its count: text full of real
  ligatures still makes a bitmap a run.

## Evidence

- `CoreTextPlainRunTests`: for 26 runs (words, numbers, paths, and the usual ligature sequences) in four styles and five
  fonts (Menlo, Maple Mono, SF Mono, Monaco, Courier New), every run said to be plain is its characters side by side,
  pixel for pixel; `!==` and `a->b` are not plain in Maple Mono and are with ligatures off.
- `RunShapingTests+Plain`: with a source that says so, a plain run keeps no bitmap, the picture equals the one with
  ligatures off, a run with a ligature is still one piece, 2,000 new words keep 12 bitmaps; the byte bound holds.
- The same probe after:

| | per new line, p50 | bitmaps held after 4,000 lines |
| --- | --- | --- |
| ligatures on, after | 20 µs (Menlo), 47 µs (Maple) | 38, **23 KB**; 40, **28 KB** |

- `SubstitutionReachTests`, on tables built to the spec layout: a ligature, a chained rule (it fires only when every
  position can be filled and its lookup changes the glyph), a single substitution to the same glyph (no change), a
  feature variation's alternate, features off by default or turned off, a `morx` noncontextual subtable on and off; Menlo's
  `morx` and a built `GSUB` cut short at every length and changed at random 3,000 times each read or are malformed, never
  trap.
- `CoreTextFastPathTests`: on every monospaced family installed (12 here, Menlo, SF Mono, JetBrains Mono, Geist Mono,
  Maple Mono among them), four styles, ligatures on and off, 2,000 seeded random runs of safe bytes each shape to their
  characters' own glyphs; one in 200 is also its characters' bitmaps side by side. Menlo lets go `f` only (its `morx`
  ligates `fi` and `fl`); Andale Mono (no table) keeps all 94. Before t241's reading, Menlo kept none.
- The same random check, 20,000 runs a style, on downloaded Fira Code 6.2 and Monaspace 1.400 variable (Neon, Xenon,
  Radon, every named instance): no run said safe shapes. Safe bytes in the regular style with ligatures on: JetBrains Mono
  71, Fira Code 66, Monaspace Neon 74, Geist Mono 93, Menlo 93. Reading the tables takes at most 3.6 ms a face.
- GlyphProbe (release, 3,000 lines, ligatures on, two runs each): `record` p50 44 → 34 µs (JetBrains Mono), 20 → 11 µs
  (Geist Mono), 19 → 11 µs (Menlo).

## Not established

- **A word with a byte that is not safe is still shaped**, once for each distinct word: JetBrains Mono lets go 23 bytes
  (`calt` and `ccmp` rules on punctuation), the normal-width italics of Monaspace more than half. The reach is an
  over-approximation: lookup flags are left out and which glyph of a rule is taken out is chosen by a fixed cost, not by
  what is cheapest overall.
- Fira Code and Monaspace were checked once on this Mac; they are not in the repository, and CI checks only the fonts its
  machine has.
- Run bitmaps are not shared between terminals of one font, nor let go one by one: the table starts again as a whole.
- Fonts with ligatures other than Maple Mono were only checked for exactness, not looked at.
