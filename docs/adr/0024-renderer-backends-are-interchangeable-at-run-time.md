---
status: proposed
date: 2026-11-05
---

# 0024 — Renderer backends are interchangeable at run time: GPU acceleration is a switch, and the CPU renderer is a product

## Context

Owner (2026-11-05): "mind the GPU acceleration and leverage, it would be interesting to have it toggleable." ADR-0006 already has a CPU reference renderer beside Metal; ADR-0021 fixed the GPU baseline (dirty-row instance rebuild, partial upload, one instanced draw) and left power, shaping and quiet-machine measurements open. This ADR makes the toggle part of the design so the screen model and the first renderer are shaped for it.

## Proposal

- **One seam, two backends.** A `CellRenderer` takes a frame description and produces pixels for a surface: the CPU renderer (SIMD where measured to pay) and the Metal renderer. The core and the screen know neither.
- **The screen is the truth, a frame is a read-only description.** What a renderer reads per frame: the dirty rows since its last frame (the screen keeps per-row dirty bits and a frame counter from now on), cell bytes of those rows, the style table, cursor, selection and search overlays, image placements. A backend keeps its own caches (instances, atlas) and can be dropped and rebuilt from the screen at any time. That makes switching a rebuild, not a migration.
- **Toggle at run time**: a setting (`renderer = auto | gpu | cpu`), a command-line flag, a remote-control command (ADR-0022) and a menu item; switching loses no state and shows no blank frame (build the new backend's first frame before presenting it). `auto` picks the GPU when a device exists and falls back to the CPU renderer on device loss or creation failure, with the reason recorded.
- **Same output, defined tolerance.** The two backends are held to one visual contract by differential tests: render the same screens on both and compare pixels, exact for glyph coverage and background fills, with a stated numeric tolerance only where blending maths legitimately differs (to be set from the first measurement, not guessed). The CPU renderer is the oracle for the GPU one.
- **Leverage the GPU where it can win, measured**: cell instance draw first (ADR-0021); then image compositing (kitty graphics, scaling and cropping), background images and blur, colour-pipeline work (linear-light blending, contrast adjustment, ADR-0009), and animated effects, each as an optional stage the CPU backend either implements slowly or declares unsupported (an explicit capability list, never a silent difference).
- **Honest cost model**: the GPU path's fixed cost is the command path (about 20-25 µs per frame, ADR-0021); a terminal that changes a few rows may be cheaper on the CPU, and the GPU's case is large windows, many images, effects, and (to be measured) energy. The toggle is how we find out per workload.

## To establish (probes, none run yet)

1. CPU renderer frame time and energy against Metal on the same screens at 120x40, 300x80 and 4K, scrolling, dense colour, large images (extends T0.5/ADR-0021, which did not measure power).
2. The pixel differential: how close can the two backends be, and where do they differ by necessity (subpixel positioning, gamma)?
3. Switch latency and flicker; behaviour on GPU loss; integrated vs discrete and external GPUs.

## Consequences

- The screen keeps per-row dirty bits and a frame counter (implemented with the screen model, tested).
- The renderer roadmap (0008) starts with the CPU renderer behind the seam, then Metal, and has the differential test as its first gate.
- Linux (Vulkan, much later) is a third backend behind the same seam.
