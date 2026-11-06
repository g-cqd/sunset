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

## Progress (2026-11-05, later): screen v1 (ADR-0025)

Done: grid with row map, 8-byte cells, wide characters, autowrap/pending wrap, C0, cursor motion, tabs, IND/NEL/RI, ED/EL/ECH/ICH/DCH/IL/DL/SU/SD/REP, scroll regions, origin and insert modes, SGR (incl. colon colours and underline styles), back-colour erase, alternate screen (47/1047/1049), save/restore cursor, DECALN, RIS, wrap flags, dirty rows (ADR-0024). 66 tests, 0 mallocs.
Not done: grapheme clusters, charsets, left/right margins, resize/reflow, scrollback, replies (DA/DSR/DECRQM/XTVERSION/OSC queries), titles and other OSC, hyperlinks, kitty keyboard/mouse/sync output/graphics, DECSCUSR and soft reset, `esctest`/`vttest` fixtures, oracle differential, the per-character cost of the non-ASCII path.

## Progress (2026-11-05, later still): replies and modes (ADR-0026)

Done: reply queue, DA1/DA2, DSR/CPR/DECXCPR, window size, DECRQM, XTVERSION, DECSCUSR, DECSTR, mode state for the host (mouse, bracketed paste, focus, sync output, keypad), kitty keyboard flag stack; 85 tests.
Not done: OSC (titles, colour queries, 8, 52, 7, 133), DECRQSS/XTGETTCAP, title stack, graphemes, charsets, resize/reflow, scrollback, kitty mouse/graphics, `esctest`/`vttest`, oracle comparison of every reply.

## Progress (2026-11-05, OSC): ADR-0027

Done: string terminator in the sink, OSC 0/1/2 titles (sanitised, never reported), title stack, OSC 4/104 and 10-12/110-112 with queries, host-seeded palette; 104 tests. Not done: OSC 8, 52, 7, 133 and notifications (need ADR-0010), named colours, DECRQSS/XTGETTCAP, graphemes, charsets, resize/reflow, scrollback, kitty mouse/graphics, `esctest`/`vttest`, oracle comparison.
