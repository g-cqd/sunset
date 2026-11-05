---
status: accepted
date: 2026-11-05
supersedes-in-part: 0017 (the tooling: bench/repro.sh and the probe's QUICK mode are research tools, not the benchmark harness)
---

# 0018 — Benchmarks rely on ordo-one/benchmark, under the standard contention profile

## Context

Owner (2026-11-05): benchmarks should rely on ordo-one's package-benchmark. TerminalKit and ask already do (TerminalKit `Benchmarks/` package, `Scripts/benchmarks.sh`, its ADR-0017 "time benchmarks compare two runs on one machine"), pinned exact at 1.38.0. ADR-0017 here chose the rules (contention profile, percentiles, deterministic gates) but measured them with hand-made probes.

## Decision

- Every benchmark is a `Benchmark(...)` in a package of its own (`Benchmarks/`), on `ordo-one/benchmark` pinned **exactly**, release only, as TerminalKit does. Hand-written probes stay research tools under `docs/research/probes`; a number that gates anything comes from this harness.
- Metrics per benchmark: `.wallClock`, `.instructions`, `.mallocCountTotal` (plus `.throughput` or others when they mean something).
- Thresholds (`BenchmarkSupport/Thresholds.swift`): **instructions** p50 within 1 %, **allocations** exact, **wall clock on p25 only** (15 %); median and tail are reported, not enforced. The wall-clock rule is TerminalKit's, from its own measurement on a loaded machine (25th percentile moved at most 9 %, the median up to 92 %, the 90th percentile up to 142 %).
- `Scripts/benchmarks.sh [--contend]` runs the suite; `--contend` holds the ADR-0017 contention profile for the length of the run (`bench/hog.c`, one spinning thread per logical CPU at user-interactive QoS). Baselines and comparisons (`baseline`, `compare`) are taken in one sitting.

## Evidence

- Read: `.instructions` on macOS comes from `proc_pid_rusage` (`ri_instructions`, `OperatingSystemStatsProducer+Darwin.swift` in the 1.38.0 checkout), the counter ADR-0017 found stable to 0.07 %; on Linux from a perf-counter shim, so the same gate exists on both targets.
- Probed (diary 2026-11-05-01): under 8 spinning threads the harness reported 108 M instructions for the scrolling stream, the same figure the hand probe gave (108.0 M) with a different driver; 0 mallocs.
- Not probed: the harness's own overhead on a 1 MiB, ~10 ms iteration; its behaviour on Linux; whether `benchmark thresholds check` passes across two contended sittings (roadmap 0014 follow-up).

## Consequences

- The VT-model probe now lives in `Benchmarks/` as `VTModelBenchmarks` (16 benchmarks) and is the first suite; T0 probes that produce numbers move to this harness as they are re-run.
- A helper to read instructions outside the harness (for the invariants in tests) may be promoted to Aemi (`AemiMetrics`); tracked separately.
