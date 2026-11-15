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

## Not established

- **Shaping is still paid once for each distinct word**: 16 to 43 µs a line of new words more than with ligatures off. Not
  shaping words that cannot change needs the font's substitution tables read; not done.
- Run bitmaps are not shared between terminals of one font, nor let go one by one: the table starts again as a whole.
- Fonts with ligatures other than Maple Mono were only checked for exactness, not looked at.
