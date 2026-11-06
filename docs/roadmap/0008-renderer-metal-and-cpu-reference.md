---
status: not-started
blocked-by: 0003, 0006, 0007
date: 2026-11-05
---

# 0008 — Renderer: CPU reference, then Metal (ADR-0006)

Atlas, instanced cells, damage and pacing; idle wakeups ~0 (TerminalKit roadmap 0025 sets the method); device-loss recovery. Gate: frame time p99, idle wakeups, colour accuracy tests.

## Added 2026-11-05 (ADR-0024, owner request)

GPU acceleration is toggleable at run time (`auto | gpu | cpu`, flag, remote-control command, menu), behind one `CellRenderer` seam; the CPU renderer is a product and the oracle for the GPU one; a pixel-differential test between them is the first gate; the GPU is leveraged beyond cell quads (images, effects, colour pipeline) only where measured. Probes listed in ADR-0024.
