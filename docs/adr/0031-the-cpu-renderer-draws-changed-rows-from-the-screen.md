---
status: accepted
date: 2026-11-05
---

# 0031 — The CPU renderer: cells to pixels, changed rows only, glyphs from a source behind a seam

## Decision (v1)

- **`SunsetRender`** (platform-free): `Surface` (RGBA8), `RenderMetrics` (cell size, padding, decoration rows), `GlyphSource` (the seam: coverage bitmaps for a character or a cluster, bold/italic, one or two cells wide, asked once per distinct glyph, answers kept), `CellRenderer` (the protocol the GPU backend will also adopt: ADR-0024), `CPURenderer`, `BoxGlyphSource` (test double: boxes), `PNG` (a minimal writer, to look at the output).
- **`CPURenderer`** reads a `Screen` and draws into a surface: background, glyph blended over it by coverage, decorations (single, double, curly, dotted, dashed underline in the underline colour; strikethrough; overline), inverse, faint (half way to the background), invisible, text blink by the host's phase, wide characters across two cells, clusters asked for whole, block, underline and bar cursors by the host's blink phase and the program's show/hide, reverse video. Colours resolve through the screen's palette (so OSC 4 and 10-12 show). It redraws the rows the screen marks dirty, the rows the cursor left and entered, and everything when the size, the palette, reverse video or the text blink phase changed; the caller clears the dirty marks.
- **`SunsetRenderMac`** is the platform seam: `CoreTextGlyphSource` rasterises with CoreText (any installed font; CoreText substitutes fonts for CJK and emoji) and derives the cell metrics from the font. `sunset-render` runs a program headless and writes its screen as a PNG, with no window.
- Not in v1, on purpose: colour management (blending is in sRGB bytes; ADR-0009's pipeline is later), the cell-exact drawing of box and block characters (below), subpixel positioning and LCD text, ligatures, selection and search overlays, images, a glyph atlas shared with a GPU backend, damage rectangles finer than rows, and the run-time toggle between backends (only the protocol exists).

## Evidence

- 19 renderer tests (`Tests/SunsetRenderTests`): empty screen, a glyph's place and colour, space, palette, 256 and true colour, inverse, faint, invisible, double width, the glyph cache (once per distinct request), every decoration, the three cursor shapes and their hiding, a cursor on a wide character, reverse video, palette change, padding, PNG checksums and structure. **A randomised differential test** (120 random screens, 25 random chunks each, from text, wide characters, clusters, colours, attributes, cursor moves, scrolling, erasing, cursor shapes, reverse video, palette changes, the alternate screen and region changes, with random cursor blink phases): the pixels after incremental frames equal those of a fresh full draw, every time. A resize draws everything; a frame with nothing dirty draws nothing.
- Looked at, not only asserted: `docs/research/renderer-first-image-2026-11-05.png` is the renderer's drawing, through CoreText and Menlo 16, of colours, bold, italic, faint, underline, curly underline, strikethrough, inverse, line drawing, CJK, an emoji and an accent: all as intended except box drawing (below).
- Instructions p50 on a 120x40 screen of coloured text, 960x640 pixels, box glyphs (the renderer's own cost, not a rasteriser's): **full frame 27 M, 0 mallocs** (1.3 ms wall, noisy); **one changed row about 0.5 M** (the benchmark's frame included the previous cursor row, so 1.08 M for two rows); a frame where only the cursor moved 1.07 M, 0 mallocs (the 14 mallocs of the changed-row benchmark come from its own string building).

## Not established

- **Process:** the renderer was written before its tests (no red first); the tests then passed after two corrections of my own wrong pixel coordinates in them. The differential test is the real guard.
- Speed against anything else: none measured (no comparison with the oracles' renderers, no frame-time measurement on real fonts). 4 500 instructions per cell is a first number, with obvious fat: a whole row strip is cleared before drawing, pixel writes are bounds-checked, colours are resolved per cell, the glyph cache is a dictionary.
- **Box and block characters from the font do not join** at cell edges (line drawing looked broken in the first image: Menlo's cell is taller than the font's line). Terminals that look right draw these characters procedurally to the cell; that is next.
- The CoreText source draws emoji in grey (a gray context); colour glyphs need an RGBA atlas. Font fallback widths are clipped, not fitted. Only Menlo at 16 pt has been looked at.
- Nothing has been drawn in a window and the GPU backend does not exist, so the run-time toggle of ADR-0024 is still a design.
