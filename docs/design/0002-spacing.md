# 0002 — Spacing: when two gaps must match, add space

The owner's rule (2026-11-12, notes n63 and the reply after): when two gaps are aligned to each other (a glyph's distance from the row's edge and
from its text, a padding against a spacing), the smaller one grows to the larger; space is not taken away to make them equal.

Applied first in `GlyphSpacing.toText` (7 pt between a row's 18 pt glyph frame and its text): measured on a selected sidebar row, edge to ink
9 pt, ink to text 8.5 pt (from 7.5 before).
