---
status: proposed
date: 2026-11-05
---

# 0005 — Cell colours are stored inline; no process-wide append-only style table

TerminalKit ADR-0021 interns styles in a process-wide, append-only table: right for ask (about 6 styles in the composer, ~60 in KittyCode), wrong for an emulator that receives arbitrary programs' colours (gradients, truecolor half-block images: millions of styles). kitty stores colours inline in each cell (`GPUCell`: fg, bg, decoration colour, sprite index, attrs: 20 bytes; `CPUCell`: 12 bytes; read from `kitty/line.h`); Ghostty uses reference-counted style sets per page (from its source tree layout, not read in depth).

**Proposal:** inline colours, or a per-screen reference-counted style set; decided by probe T0 (roadmap 0002): memory and time per cell under a truecolor stress stream versus an interned table.
**Not yet measured.**
