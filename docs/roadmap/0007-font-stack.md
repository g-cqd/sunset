---
status: partly-done (as of 2026-11-11: Ligatures and OpenType features through CoreText (ADR-0032); font family, size, ligatures and features are settings. The own font stack is not built.)
blocked-by: 0001
date: 2026-11-05
---

# 0007 — Font stack (ADR-0008)

OpenType parsing, shaping, fallback and rasterising; CoreText as the macOS oracle (glyph-level comparison); FreeType and HarfBuzz outputs as external oracles on Linux. Also needs research R10 (CoreText internals, shared with TerminalUI's research).

## Progress (2026-11-05): ligatures and font features through CoreText (ADR-0032)

Owner note n2. Done: run shaping in the glyph seam and the CPU renderer, grid-snapped glyph placement, OpenType features and ligature on/off in the CoreText source, tests and a picture. Not done: configuration, variable fonts, per-style fonts and fallback order, the own font stack (ADR-0008: parsing, shaping and rasterising with CoreText as the oracle), a GPU atlas that shares run shaping.
