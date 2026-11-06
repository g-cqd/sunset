---
status: accepted
date: 2026-11-05
---

# 0028 — Scrollback is a ring of fixed-width lines; resize re-wraps the primary screen and its history

## Decision (v1, hot history only)

- **History**: lines that leave the top of the primary screen by a line feed (region top at the screen top, not the alternate screen) go to a ring of at most `scrollbackLimit` lines (default 10 000), each as wide as the screen was, with its wrap flag. Deleting lines, a region below the top and SU do not save. ED 3 clears it; ED 2 does not. The compressed cold form (ADR-0013) is later.
- **Resize** (`Terminal.resize`): the primary grid and history are joined into logical lines (a row that wrapped continues on the next), trailing blank cells dropped, and split again at the new width. A double-width character is never split (a `spacerHead` blank marks the end of a row it did not fit and is dropped on the next reflow). The cursor and the top of the screen are followed through the change; the screen keeps its top row unless the cursor would fall below it; blank rows below the cursor are dropped before any line goes to history; when the cursor was on the last row and there is room, history is pulled back to fill the screen. The alternate screen is cut or padded, never re-wrapped; the scroll region is reset; tab stops of the new columns are the defaults; every row is dirty.
- **Styles and history**: the style table cannot hold every style of a long colourful history. A rebuild (when the 65 536 ids are used) keeps the screens' styles first, then the history's newest line first up to three quarters of the table; older history loses its styles (default). A rebuild therefore happens at most once per 16 384 new styles. (The first version rebuilt on every new style once the history alone exceeded the table and stopped responding: found by the test suite hanging.)

## Evidence

137 tests pass (`ScreenScrollbackTests`, 24 new): history order, ring limit, what saves and what does not, ED 3, wrap flags and styles in history, width change both ways, hard breaks kept, cursor tracking (including in blank space), height change both ways with and without history, wide characters, history re-wrapped, alternate screen resize, tab stops, dirty rows, and a randomised property: for 150 random texts and random sequences of resizes (width 2-15, height 1-7) the logical lines (history plus screen) are unchanged. Streams: 0 mallocs; ASCII 57 M instructions per MiB (50 M before history saving, which copies a row per scrolled line), OSC titles 190 M (titles now do real work; 102 M before they did).

## Not established

No comparison with other terminals' reflow (kitty, ghostty, wezterm differ in details, for example in which rows are kept after a shrink); the cursor on a wrapped line when the new width splits exactly at the cursor is chosen, not compared; saved-cursor (DECSC) positions are clamped, not re-wrapped; resize while the alternate screen is active re-wraps the primary using the cursor saved at entry (none, with 47/1047: top left); no cap on the requested size (the host decides); the history ring copies `columns` cells per scrolled line (about 2 K instructions at 120 columns, measured as +7 M per MiB of ASCII), not yet optimised beyond one `replaceSubrange`.
