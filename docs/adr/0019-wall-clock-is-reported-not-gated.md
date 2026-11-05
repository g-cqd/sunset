---
status: accepted
date: 2026-11-05
supersedes-in-part: 0018 (the wall-clock p25 threshold)
---

# 0019 — Wall clock is reported, not gated; instructions and allocations are the gate

## Context

ADR-0018 adopted TerminalKit's threshold rule: wall clock gated on its 25th percentile within 15 %, because TerminalKit measured that percentile moving at most 9 % between runs of the same code at a load average of about 10. This machine, while the first full contended comparison ran, was at a load average of 25–32 *plus* ADR-0017's eight spinning threads.

## Probe

`Scripts/benchmarks.sh --contend baseline contended-a`, then `compare contended-a`, immediately after, same tree against itself, 16 benchmarks (`VTModelBenchmarks`), ordo-one/benchmark 1.38.0, Apple M3.

| Metric | Spread between the two runs of identical code |
|---|---|
| Wall clock p25 | **−44 % to +56 %**; beyond ±15 % in 11 of 16 benchmarks |
| Wall clock p50 | −14 % to +66 % |
| Wall clock p90 | +11 % to +90 % |
| **Instructions p50** | **0 % in all 16** |
| **Allocations** | **0 in all 16, no difference at any percentile** |

## Decision

- The gate is **instructions (p50 within 1 %) and allocations (exact)**. `Thresholds.perSuite` no longer carries a wall-clock threshold.
- Wall-clock percentiles stay in the reports as the realism check (cache and memory effects instructions cannot see) and are compared **within one sitting, with the variants interleaved**; a wall-clock regression is read from such a comparison by a person, not enforced by a threshold.
- If a quieter regime is ever the norm (a dedicated machine or runner), re-probe before re-introducing a wall-clock threshold.

## Consequences

- TerminalKit's p25 rule is not adopted here; this does not say it is wrong at its load, only that it does not hold at this one.
- CI on a shared runner gets the same property for free: the gates do not depend on neighbours.
- Cost: a slowdown that keeps the instruction count (a cache-miss regression, a lock, a syscall) passes the gate. Mitigation: mallocs and syscalls (`.syscalls`, if the harness provides it) are added where relevant, and wall clock is read by a person on every performance change.
