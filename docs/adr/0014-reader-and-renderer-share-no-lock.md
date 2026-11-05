---
status: proposed
date: 2026-11-05
---

# 0014 — The PTY reader and the renderer share no lock

## Context

Alacritty needed a fair mutex and `try_lock` batching (1 MiB read buffer, release after 65,535 bytes); Ghostty needed a demand-handoff protocol because unfair locks let the parse loop starve the renderer (`renderer/State.zig`).

## Proposal

The reader owns the screen. The renderer raises an atomic *frame wanted* flag; between parse chunks the reader publishes the dirty rows (and cursor, modes) into a triple buffer and clears the flag. Nobody waits on anybody; cost is O(dirty cells) on the reader, bounded per chunk.

## Open

Probe (roadmap 0002): unfair mutex, fair mutex, Ghostty-style demand handoff, snapshot-on-request, under sustained output; reader MB/s and renderer stall p99. Adopt only if it wins on both; otherwise adopt the best measured variant.

## Evidence so far (probe T0.3, `Benchmarks/Probes/HandoffProbe`; machine at load average 39–43 from other work, so rankings are NOT established)

Reader parses vtebench-like streams in 64 KiB chunks while a renderer asks for a consistent copy of the 120x40 screen every 8.33 ms; "wait" = request to copy in hand.

- **Robust in every run:** the unfair lock (`os_unfair_lock`, the platform lock Ghostty describes) starves the renderer: p50 wait 1–3 µs but **p99 40–384 ms and a maximum of 1.03 s** (log stream), against a 8.33 ms frame. Fair lock, demand handoff and snapshot-on-request all bounded the tail far below that (typically 1–60 ms at this load).
- **Not established:** the order among fair, demand, snapshot and publish-every-chunk. Reader throughput for the same variant moved up to 3.5× between two replications minutes apart (dense_cells "publish" 130.8 vs 36.9 MB/s) because the machine's load changed. The snapshot-on-request variant depends on the reader being scheduled to answer (wait p50 1–4.5 ms under load, bounded by the chunk time); the lock-based variants do not. A variant that publishes after every chunk (renderer never asks, never waits; "wait" is then the age of the screen, 0.3–4.6 ms median) is the obvious refinement and was added.
- The probe needs a quiet or tightly contended machine; ADR-0017's hog profile cannot help when ambient load is 5x the core count. Re-run owed.
