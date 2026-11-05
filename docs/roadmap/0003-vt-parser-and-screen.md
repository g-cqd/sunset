---
status: not-started
blocked-by: 0002
date: 2026-11-05
---

# 0003 — VT parser and screen model (headless)

Red tests first from `esctest` and `vttest` fixtures, with the gap list published. Parser, grid and scrollback, alternate screen, modes, DECRQM, device attributes, XTVERSION, OSC 4/10/11/12 queries, kitty keyboard flags, mouse modes, synchronized output. Gate: pass list, vtebench throughput against the oracles on our harness, 0 mallocs per MB in steady state.
