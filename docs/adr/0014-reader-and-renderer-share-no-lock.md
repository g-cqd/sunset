---
status: accepted
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

## Evidence, second round (3 s per cell; first run at load average 6–16, second at 25–54)

First run (the usable one; machine nearly quiet at its start), `dense_cells` (the cleanest stream; reader alone = 150 MB/s):

| Variant | reader MB/s | frames in 3 s (of 360) | wait p50 / p99 / max |
|---|---|---|---|
| unfair lock | 150 | **14** | 2 µs / **1,487 ms** / 1,504 ms |
| fair lock | 137 | 360 | 233 µs / 525 µs / 555 µs |
| demand handoff | 150 | 360 | 229 µs / 630 µs / 887 µs |
| snapshot on request | **155** | 360 | 236 µs / 1,104 µs / 2,575 µs |
| publish every chunk | 156 | 360 | 223 µs / 493 µs / 573 µs |

`scrolling` (many scrolls, reader alone 130 MB/s): reader throughput fair 75.7, demand 47.1, **snapshot 98.8**, publish 87.1; unfair delivered **2 frames in 3 s** (first wait 555 ms). Locks cost the reader up to 64 % on this stream (it holds the screen longer per chunk); snapshot costs 24 %, publish 33 % (it copies every chunk).
The second run (load average 25–54, reader 19–23 MB/s instead of 150) shows the noise and one constant: the unfair lock again starved the renderer (p99 96–103 ms).

## Decision

- **The unfair platform lock is rejected** for the screen: it starved the renderer for up to 1.5 s in the quiet run and by 96+ ms in the loaded one.
- **Snapshot-on-request is the baseline design** (no lock; the reader publishes between chunks when asked; the renderer waits at most about a chunk time): it matched the lock-free reader throughput on the SGR stream and cost the reader least on scrolling. Publishing every chunk is the alternative when staleness matters more than reader throughput.
- Fair lock and demand handoff remain the fallback if snapshot-on-request cannot be made to hold under load: its renderer depends on the reader being scheduled (wait p99 up to 13–16 ms at load 16 on scrolling).
- Owed: a replication at low load, with the hog profile of ADR-0017 holding the load constant instead of other people's work, and the p99 of key-to-frame under those conditions.
