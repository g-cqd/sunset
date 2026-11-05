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
