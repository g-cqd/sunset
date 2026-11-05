---
status: not-started
blocked-by:
date: 2026-11-05
---

# 0002 — T0 probes (expanded after the performance study)

Settles ADR-0005/0012–0016 with numbers; every probe in the same harness, release only, percentiles, units, recorded in the diary:

1. Cell format: 8 B + page styles, 16 B + page styles, inline colours, global table; ASCII, SGR-dense, truecolor-gradient streams (time and bytes per cell).
2. Cold history: raw vs LZ4-of-page vs structural on the 139-transcript corpus and on synthetic truecolor (bytes per cell, µs per row decoded).
3. Reader/renderer handoff: four variants (ADR-0014).
4. Parser: printable-run scan with `SIMD16<UInt8>`, Aemi's C kernels, and a byte loop; `Span` bounds-check cost in the inner loop; differential test against a scalar path.
5. Metal micro-benchmark: CPU-rebuilt instances vs direct cell reads (ADR-0015).
6. Frame scheduling proxy and idle wakeups (ADR-0016).
7. Reflow cost on a large scrollback; reader backpressure with a slow consumer.

## Progress (2026-11-05)

- Probe 1 (cell format): first round done on an 8/16/32-byte model (kernels-study §7b); page splits and truecolor gradients open.
- Probe 2 (cold history): live structural encoder measured on a real-text log; real transcript corpus open.
- Probe 4 (parser): Swift model floor measured (0.6–10 ms/MiB on vtebench-like streams, noisy); safe `Span` variant, graphemes, paged styles open. Note a stream-generator error (missing ONLCR) found and fixed.
- Probes 3, 5, 6, 7 not started.
- Probe 3 (handoff): built (`Benchmarks/Probes/HandoffProbe`); unfair-lock starvation confirmed (p99 up to 384 ms, max 1.03 s); ranking of the other variants not established at load 39-43; re-run owed.
- A measured side result: hot generic code must stay `internal` behind a non-generic facade (ADR-0020).
- Probe 5 (Metal direct read): done, not supported (ADR-0021). Probes 6 (scheduling, idle wakeups) and 7 (reflow, backpressure) not started; probes 1-4 as above.
