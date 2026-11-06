---
status: in-progress
blocked-by: 0003
date: 2026-11-05
---

# 0005 — Oracle, differential fuzzing and benchmark harness

The same byte stream into ours and into kitty, ghostty, wezterm, SwiftTerm and libghostty-vt (as processes), grids compared; vtebench workloads (SwiftTerm already ports them); build on TerminalKit's DECRQM verifier. Recorded streams replay deterministically.

## Progress (2026-11-05): kitty as an oracle (ADR-0030)

`Scripts/oracle-compare.sh` compares screen text and styles with kitty on 17 streams: all the same. Not done: styles, cursor, replies, resize, ghostty and wezterm, `esctest`/`vttest`, fuzzing (differential or crash), session replay.
