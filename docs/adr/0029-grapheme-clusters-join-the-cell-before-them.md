---
status: accepted
date: 2026-11-05
---

# 0029 — Grapheme clusters: a mark or joiner joins the cell written last; the cell points at an interned cluster

## Decision (v1)

- A cell that holds more than one scalar (a letter with accents, an emoji joined to others, a flag) has a **cluster flag** and its scalar field is an id into a per-screen **cluster table** (interned, bounded at 2^20 by default; ids start at 1). A cell is still 8 bytes.
- A scalar **joins the cell written last** when the scalars so far plus this one form a single `Character` (the standard's rule, from Swift's own segmentation), and nothing but printing happened since: any control, escape, control sequence or string in between, or a resize, ends the chance (a mark after a cursor move joins nothing and is dropped, as is one with nothing before it).
- Cluster width is TerminalKit's `UnicodeWidth` (the table measured against kitty, ghostty, wezterm and Terminal.app). A cluster that becomes double-width (emoji presentation selector, a flag) takes the next cell if there is room; at the last column it stays narrow.
- A **cheap test first**: only zero-width scalars, regional indicators, emoji modifiers, Hangul vowels/finals and a scalar right after a joiner are checked; letters and CJK never allocate.
- When the table is full a mark is dropped and the base kept. Entries are never freed.

## Evidence

150 tests (13 new in `ScreenGraphemeTests`): accents, several marks, no join after a cursor move or at the start, a mark arriving in a later `feed` (byte by byte), ZWJ families, skin tones, flags (two join, the third starts the next), VS16, the last column, overwrite and erase, history and resize, the bound, interning. Benchmarks unchanged: UTF-8 stream 287 M instructions per MiB, 0 mallocs (a first version without the cheap test allocated 249 K times and ran 3x slower on CJK text, caught by the benchmark).

## Not established

No comparison with the oracles on the contested cases (`UnicodeWidth.isContested`: ZWJ sequences, VS16, lone regional indicators), which terminals disagree on; Prepend-class scalars, Indic conjuncts and other rare clusters are only handled if the standard test above says they join *and* the cheap test lets them through; the join path allocates (a `String` and an array), only reached for the scalars above; the cluster table is not compacted; a cluster cell repeated by REP repeats its base scalar only.
