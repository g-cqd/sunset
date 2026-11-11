---
status: not-started (as of 2026-11-11: Study done; nothing changed in Aemi (task t140).)
blocked-by: 0002 (parser and cell-write probes decide which kernels matter)
date: 2026-11-05
---

# 0015 — Kernel candidates for Aemi (study done, work not started)

Study and first three probes: research/kernels-study.md. Proposed entries for Aemi: a kernel-selection ADR (libc first, intrinsics next, assembly only past a pre-set measured bar), a mismatch-index family, bulk C0 positions and UTF-8 decode-until-control, an own LZ4 block codec benchmarked against libcompression, inflate/Adler-32/CRC-32/PNG unfilter, a row hash. **Nothing was changed in Aemi.** Scanning is not the terminal's bottleneck (kitty's end-to-end 60–250 MB/s vs 5–10 GB/s scanning), so the cell write path and the state machine come first.
