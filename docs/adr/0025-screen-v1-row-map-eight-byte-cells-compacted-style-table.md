---
status: accepted
date: 2026-11-05
---

# 0025 — Screen v1: a row map over 8-byte cells, one interned style table that compacts when full

## Context

Roadmap 0003 needs a screen the parser can feed. ADR-0012 (8-byte cell, page-local reference-counted styles) is still proposed, pending probes of page splits. The screen must not block on that, must be correct first, and must leave room for ADR-0024 (renderer backends read the screen, per-row dirty tracking) and for scrollback.

## Decision (v1, refinable)

- **Cell**: 8 bytes: scalar (21 bits, 0 = empty), width class (narrow / wide head / spacer tail), 16-bit style id. Wide characters occupy two cells; any write or erase that would cut one in half blanks the other half.
- **Rows**: a grid of `rows × columns` cells reached through a row map (screen row → physical row), so scrolling a region rotates row numbers (three reversals, in place) and blanks the rows that arrive, instead of moving cells. A per-row `wrapped` flag records that a line continued on the next (reflow, selection and semantic copy will need it).
- **Styles**: one table per screen, interned (`CellStyle` → id, id 0 = default). No reference counts, so a cell write pays nothing for them. When the 65 536 ids are used up the screen **compacts**: it rebuilds the table from the ids still in cells and rewrites the cells. Erased cells carry only the pen's background (back-colour erase). This is not ADR-0012's page-local scheme; it is the simplest bounded one, and scrollback will need its own storage for styles of rows that left the grid.
- **Primary and alternate** grids are swapped, not copied; 47, 1047 and 1049 follow xterm.
- **Dirty rows and a generation counter** are kept from the start (ADR-0024); a renderer asks `isDirty(row:)` and calls `clearDirty()`. Scrolling dirties the region's rows (a renderer cache that shifts rows instead is a later optimisation).
- **ASCII runs** are written a row at a time (one pass, one dirty mark, wide-character edges checked at the two ends).
- Gaps by design for now: zero-width scalars (combining marks, joiners, variation selectors) are dropped, i.e. no grapheme clusters; no charsets (DEC line drawing); no left/right margins; no resize or reflow; no scrollback; no replies; strings (OSC, DCS, APC) are consumed and ignored.

## Evidence (`Tests/SunsetCoreTests`, 66 tests in all; `bench/results/2026-11-05/parser-and-terminal.txt`)

- 42 directed tests for printing, wrap (pending-wrap semantics), wide characters, cursor motion and clamping, tabs, IND/NEL/RI, erase, insert/delete, scroll regions, origin mode, DECALN, RIS, SGR (semicolon and colon forms, underline styles), back-colour erase, alternate screen, wrap flags and dirty rows. They were written before the implementation but only compiled against a skeleton, so the implementation was not run against a behavioural red first; instead I **mutated the implementation ten times** and required a failing test: eight were caught at once, two survived (1049 not clearing the alternate screen on entry; the wrap flag not cleared by EL), tests were added, and both are now caught. A third mutant (a wrong ASCII-run length) only crashed the run, which counts as caught.
- A style-table test writes 200 000 distinct truecolour styles: compaction runs and the last cell keeps its colour.
- A differential test holds the row-at-a-time ASCII path against a naive character-at-a-time model on 400 random streams with random cuts (print, CR, LF, BS, HT, random sizes): equal text and cursor.
- Instructions per 1 MiB, p50, 120x40, release: ASCII 50 M (190 M before the row-at-a-time path), cursor moves 142 M, OSC titles 102 M, truecolour SGR 153 M, UTF-8 text 268 M; **0 mallocs in all five**, scrolling included. Wall clock was noisy (machine loaded) and is not reported as a result.

## Not established

- Whether this beats the oracles: no comparison has been run (roadmap 0014/0005). The numbers are a first baseline, not a claim.
- The wide-character width comes from TerminalKit's table through `Character(scalar)` per scalar; its cost in the UTF-8 stream (268 M) is unexamined.
- Compaction cost when it triggers (a pause proportional to the grid) is unmeasured; it needs 65 536 distinct styles *printed*, which real programs rarely approach.
- ADR-0012's page-local styles and 8-byte cell remain the target; this ADR does not settle them.
