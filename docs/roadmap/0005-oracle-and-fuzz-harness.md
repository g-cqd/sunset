---
status: partly-done (as of 2026-11-11: kitty, ghostty, alacritty compared by script on 18 streams and a reply stream. Not built: wezterm, esctest/vttest, cursor and resize comparison, fuzzing.)
blocked-by: 0003
date: 2026-11-05
---

# 0005 — Oracle, differential fuzzing and benchmark harness

The same byte stream into ours and into kitty, ghostty, wezterm, SwiftTerm and libghostty-vt (as processes), grids compared; vtebench workloads (SwiftTerm already ports them); build on TerminalKit's DECRQM verifier. Recorded streams replay deterministically.

## Progress (2026-11-05): kitty as an oracle (ADR-0030)

`Scripts/oracle-compare.sh` compares screen text and styles with kitty on 17 streams: all the same. Not done: styles, cursor, replies, resize, ghostty and wezterm, `esctest`/`vttest`, fuzzing (differential or crash), session replay.

## Progress (2026-11-05, three more oracles): ADR-0030 addendum

Ghostty (text) and alacritty (replies) added; a 27-query reply stream compared on four terminals; `Scripts/oracle-accepted.txt` lists understood differences, anything else fails the script. Not done: wezterm, `esctest`/`vttest`, cursor and resize comparison, fuzzing, deciding the ghostty back-tab question against xterm.
