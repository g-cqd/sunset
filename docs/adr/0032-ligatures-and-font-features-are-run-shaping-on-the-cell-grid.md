---
status: accepted
date: 2026-11-05
---

# 0032 — Ligatures and font features: runs are shaped as one piece, glyphs are placed on the cell grid

Owner note n2 (2026-11-06): "font rendering should support ligatures and font features."

## Decision (v1)

- **The glyph seam knows runs.** `GlyphSource` has `shapesRuns` and `glyph(forRun:...)`: a run of narrow characters of one style is shaped together and returned as one bitmap `cells` cells wide. Sources that cannot shape runs keep the per-cell path (the default).
- **The CPU renderer shapes runs when asked** (`CPURenderer(..., ligatures: true)`). A run is at least two plain narrow characters with the same style, at most 32, and ends at a blank, a style change, a wide character, a cluster, a line-drawing, block or braille cell (the renderer draws those itself), a hidden character, or **the cell with the cursor** (so the cursor always shows the one character it is on, as other terminals do). Backgrounds and decorations are still drawn per cell; the run's glyphs are drawn once over them. Shaped runs are cached by a hash of their scalars and compared with the cells on lookup (no allocation on a hit, no trust in the hash alone); the cache is emptied at 8 192 entries.
- **CoreText source** (`SunsetRenderMac`): shapes the run as one `CTLine` and draws each glyph at the left of the cell its first character is in, whatever the font's advance (a font's advance is rarely a whole number of pixels, and drawing the line as it comes drifted off the grid, which a test caught); a ligature is one glyph over several cells; fallback fonts keep their own run fonts. **Font features**: `FontFeature("zero")`, `("ss01")`, `("cv02", 3)`, ... through the font descriptor's OpenType feature settings, applied to all four styles; ligatures and contextual alternates (`liga`, `clig`, `calt`) are always stated explicitly, on by default, off with `ligatures: false`. `sunset-render --ligatures --feature zero --feature ss01=1 --no-font-ligatures` shows them.

## Evidence

- 9 run-shaping tests with a fake shaping source (runs form and end where they should, a ligature spans cell boundaries, the cursor splits a run, the same text is shaped once, a run is cut at 32, backgrounds and underlines under a run) and a **differential test** (80 random screens with runs on: incremental drawing equals a full draw). 5 tests of the CoreText source: cell size and glyphs, bold and italic differ, wide glyph width, ligatures change the pixels of `!==` in Maple Mono and with the feature off a run equals its characters side by side, and a stylistic feature changes the zero (these two pass without recording anything when Maple Mono is not installed).
- Looked at (`docs/research/renderer-ligatures-2026-11-05.png`, Maple Mono NF CN 20 pt): `->` `=>` `!=` `===` `<=` `>=` `|>` `<|` `</>` `&&` `!==` are drawn as the font's ligatures, on the cell grid, with the rest of the line unchanged; with run shaping off the same text is drawn character by character.

## Not established

- Only one ligature font (Maple Mono) has been tried; SF Mono, Geist Mono and others have not, and the zero/stylistic feature test found *some* feature that changes a glyph, not that each named feature does what its name says in any font.
- Contextual alternates that depend on characters beyond a space or a style change (a run ends there) are not applied across it; a ligature across a colour change is not drawn (the run ends at the style change), which differs from terminals that shape across colours.
- Run shaping costs more than the per-cell path (a shaping call per distinct run); not benchmarked. The default is off.
- The settings (a font, its features, ligatures on or off) have no configuration yet; the app will own them (roadmap 0009). Variable-font axes, font fallback ordering and per-style fonts are not exposed.
- The GPU backend will need the same run shaping to produce atlas entries; the seam is shared, the atlas is not designed.
