---
status: in-progress
blocked-by: 0006, 0007
date: 2026-11-05
---

# 0008 — Renderer: CPU reference, then Metal (ADR-0006)

Atlas, instanced cells, damage and pacing; idle wakeups ~0 (TerminalKit roadmap 0025 sets the method); device-loss recovery. Gate: frame time p99, idle wakeups, colour accuracy tests.

## Added 2026-11-05 (ADR-0024, owner request)

GPU acceleration is toggleable at run time (`auto | gpu | cpu`, flag, remote-control command, menu), behind one `CellRenderer` seam; the CPU renderer is a product and the oracle for the GPU one; a pixel-differential test between them is the first gate; the GPU is leveraged beyond cell quads (images, effects, colour pipeline) only where measured. Probes listed in ADR-0024.

## Progress (2026-11-05): CPU renderer v1 (ADR-0031)

Done: `SunsetRender` (surface, metrics, glyph source seam, `CellRenderer`, `CPURenderer` with dirty-row drawing and a differential test, PNG), `SunsetRenderMac` (CoreText glyphs), `sunset-render` (PNG of a program's screen, no window), benchmarks (28 M instructions a full 120x40 frame). Not done: procedural box drawing, colour emoji, selection and search overlays, images, colour pipeline (ADR-0009), a glyph atlas format a GPU backend can share, the Metal backend and the run-time toggle, a window and display pacing, probes of CPU against Metal in time and energy.
