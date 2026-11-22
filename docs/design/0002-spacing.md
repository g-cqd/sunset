# 0002 — Spacing: when two gaps must match, add space

The rule (2026-11-12): when two gaps are aligned to each other (a glyph's distance from the row's edge and
from its text, a padding against a spacing), the smaller one grows to the larger; space is not taken away to make them equal.

Applied first in `GlyphSpacing.toText` (7 pt between a row's 18 pt glyph frame and its text): measured on a selected sidebar row, edge to ink
9 pt, ink to text 8.5 pt (from 7.5 before).

## Keylines (2026-11-22)

From the grid systems (Müller-Brockmann, *Grid Systems in Graphic Design*; Elam, *Grid Systems*) and Apple's Human
Interface Guidelines ("align elements to make them easier to scan, and use indentation to convey hierarchy"): what is read
together starts on one vertical line, and a line once set is kept by everything under it.

- A sidebar's content has one leading line, `layout.tabSideInset + layout.tabPaddingLeading`: the tabs' glyphs, the
  Library's titles, its rows' glyphs, its empty states and its sentences (Passwords' among them) start on it.
- The command bar keeps two: its field's glyph and its rows' glyphs on the first, the typed text and the rows' titles on
  the second (`CommandBarGrid`, tested). In the sidebar the first is the tabs' line.
- A page of the pane area (Settings, Help, Passwords) is a grouped form of one width (`Design.Size.settingsPage`),
  centred; its rows put labels on their leading line and values on their trailing one.
- Negative space groups: within a group the scale's small steps (`hair` to `s`), between groups the large ones (`l` up);
  a step between two is moved up (above).
