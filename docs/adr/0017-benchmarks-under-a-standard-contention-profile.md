---
status: accepted
date: 2026-11-05
superseded-in-part-by: 0018 (tooling)
---

# 0017 — Benchmarks run under a standard heavy-contention profile; the gate is a deterministic metric

## Context

Owner (2026-11-05): "tests should be run under heavy contention to have reproducible results". Until now numbers were taken on whatever else the machine was doing (load average 7–28 from other work), and drifted up to 2× between runs. Aemi's kernel work already measures instructions retired in places (research E13), and aemi ADR-0011 interleaves variants in shuffled order.

## Decision

1. **Standard contention profile (SCP).** Wall-time benchmarks run while `bench/hog` holds one CPU-spinning thread per logical CPU at the benchmark's own QoS class (`hog <ncpu> <secs> interactive spin`). Oversubscription (2× threads) and memory-streaming hogs are named *stress* profiles, reported separately, not the default.
2. **Report percentiles of per-pass times (p50, p90, p99), never the best run**, and name the profile and the ambient load average next to every number.
3. **A/B comparisons interleave the variants inside one contention window** (shuffled order); wall numbers from different sessions are not compared.
4. **Regression gates use deterministic metrics**: instructions retired per unit of work (`proc_pid_rusage`, `ri_instructions`), allocations, bytes. Wall percentiles under the SCP are the realism check, not the gate.

## Evidence (probes/vtmodel2.swift QUICK mode, `bench/repro.sh`, 10 launches per condition, Apple M3 with 4 P + 4 E cores, ambient load average 8–28 from other work)

| Condition | metric | cv across launches |
|---|---|---|
| ambient, three sweeps | wall p50, scrolling / dense / log | 42 / 49 / 26 %; 9.7 / 34 / 24 %; 21 / 25 / 29 %; and 5.8 / 5.2 / 4.3 % in a calmer sweep |
| hog, 8 spin threads, three sweeps | wall p50, scrolling / dense / log | 19 / 5.5 / 2.9 %; 24.7 / 13 / 8.7 %; 23.6 / 4.8 / 9.2 % |
| hog, 8 mixed (spin + memory stream) | wall p50 | 14 / 12 / 5 %, and levels 2.5–3× higher |
| hog, 16 mixed (2× oversubscribed) | wall p50 | 39 / 40 / 37 %: worse than ambient |
| **either condition** | **instructions retired per MiB** | **0.0 %** (108.08 vs 108.01 M, 82.78 M, 28.36 M; within 0.07 %) |
| either | cycles per MiB | 1–5 % |

What this says, and does not:

- A controlled spin profile at 1× lowers the **within-sweep** spread of wall times compared with uncontrolled load in most sweeps, and the 2× oversubscribed profile makes it worse. It does **not** make wall times comparable across sessions: the same profile's p50 moved 14.0 → 24.0 → 15.7 ms (scrolling) between three sweeps because other users' work still leaks through. Hence rules 3 and 4.
- Instructions retired were identical to 0.07 % under every load tried, so they can gate regressions at 1 % where wall time cannot. They do not see cache or memory behaviour, which wall time under the SCP exists to catch.
- Not probed: other machines, thermal throttling over long runs, whether E-core placement of the benchmark thread changes the picture (QoS interactive keeps it on P-cores here), the `cycles` counter's scale (it read about half of what a 4 GHz core would give for the elapsed time; used only as a relative number).

## Consequences

- The white paper's performance doctrine (§2) gains these rules in both new repositories; TerminalKit's and ask's papers are unchanged (their loops note the load average).
- The competitor pass (roadmap 0014) and every T0 probe are re-run under the SCP before their numbers are used.
- Cost: each benchmark session burns every core; it cannot share a machine with interactive work, which defeats part of the point on a shared workstation. Accepted.
