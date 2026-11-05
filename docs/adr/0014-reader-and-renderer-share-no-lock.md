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
