---
status: in-progress
blocked-by:
date: 2026-11-05
---

# 0003 — VT parser and screen model (headless)

Red tests first from `esctest` and `vttest` fixtures, with the gap list published. Parser, grid and scrollback, alternate screen, modes, DECRQM, device attributes, XTVERSION, OSC 4/10/11/12 queries, kitty keyboard flags, mouse modes, synchronized output. Gate: pass list, vtebench throughput against the oracles on our harness, 0 mallocs per MB in steady state.

## Progress (2026-11-05)

- Parser done to its first contract (ADR-0023): states, UTF-8, C1, bounded parameters, strings with limits, `ParseCounter`; 24 tests; 0 mallocs; baseline instructions per MiB recorded.
- Not done: the screen (grid, cursor, scrolling, modes, SGR), scrollback, alternate screen, replies (DA, DSR, DECRQM, XTVERSION, OSC colour queries), kitty keyboard/mouse/sync output, `esctest`/`vttest` fixtures and the gap list, differential tests against the oracles, the CSI cost, the vector path, fuzzing beyond random streams.
- Probes 6 and 7 of roadmap 0002 (scheduling, reflow/backpressure) were not run; the screen design here follows the accepted ADRs 0012-0014 and does not wait for them.
