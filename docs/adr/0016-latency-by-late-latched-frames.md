---
status: proposed
date: 2026-11-05
---

# 0016 — Frames are scheduled against vsync and latched as late as safe; idle schedules nothing

## Context

kitty rate-limits wakeups (`input_delay`, `repaint_delay`); WezTerm coalesces with a delay; both trade latency for CPU with fixed knobs.

## Proposal

Start each frame at (next vsync − measured p99 frame cost − margin), so bytes that arrive until then are included; wake once per frame at most; with nothing dirty, no timer and no wakeup (TerminalKit roadmap 0025). Fixed delays only as a fallback.

## Open

A software latency proxy (key → presented time from the display link's feedback) against fixed-delay schedules, and wakeups/s idle. Key-to-photon needs hardware and is not claimed.
