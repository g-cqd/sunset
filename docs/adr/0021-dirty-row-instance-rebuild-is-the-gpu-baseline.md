---
status: accepted
date: 2026-11-05
supersedes: 0015
---

# 0021 — The GPU baseline is a dirty-row instance rebuild with partial upload; the screen is not the vertex buffer

## Context

ADR-0015 bet that wrapping the screen's page-aligned cell memory as a Metal buffer and decoding cells in the vertex shader would beat rebuilding instance data on the CPU each frame, on unified-memory Macs (Ghostty rebuilds a 32-byte instance per glyph; kitty uploads its cell array).

## Probe (T0.5, `Benchmarks/Probes/MetalProbe`, Apple M3, offscreen 1080x720 and 2700x1440, 600 frames, per-frame p50 in µs; machine at load average 18–30 from other work, GPU times varied up to 2× between identical runs, so only large differences count)

| Variant | CPU prepare, 120x40 | CPU prepare, 300x80 | CPU encode+commit | GPU time |
|---|---|---|---|---|
| A-full: rebuild every instance, upload all | 15–17 | 73 | 21–71 | 284 / 710–800 |
| A-dirty: rebuild the changed row, upload that row | **2–3** | **3–6** | 24–75 | 284 / 709–1295 |
| B: the cell buffer is the vertex buffer | **0.1–0.3** | **0.1–0.2** | 21–59 | 157–286 / 710–1295 |

## Reading

- The CPU saving of B over a dirty-row rebuild is **2–5 µs per frame**, under 0.1 % of an 8.3 ms frame. B's advantage over the *full* rebuild (15–73 µs) is real but is the advantage of any dirty-aware design, which Ghostty already has.
- GPU time did **not** improve consistently: B was lower once (157 vs 284 µs at 120x40), equal in another run, and worse at 300x80 in two runs (1082–1295 vs 709–795 µs): per-instance decoding and table lookups in the vertex stage are not free.
- The dominant CPU cost in every variant is the Metal API itself: **20–25 µs per frame for encoding and committing** a one-draw command buffer.
- Not measured: power (the reason to care about GPU time), real glyph shaping (the side channel B needs for ligatures and emoji sequences), memory pressure with decommitted pages (`bytesNoCopy`), and a quiet machine.

## Decision

- ADR-0015 is rejected for now. The GPU path starts from Ghostty's scheme: per-row dirty flags, instance rebuild for dirty rows only, partial upload into a ring of buffers, one instanced draw.
- The cost to engineer is the **Metal command path** (encode + commit about 20–25 µs, fixed): one command buffer and one encoder per frame, reuse of pipeline state and argument buffers, no per-frame allocation. A probe of indirect command buffers and of CAMetalLayer presentation costs belongs with ADR-0016.
- Revisit if a quiet-machine probe with power measurement shows B's GPU time or energy materially better.
