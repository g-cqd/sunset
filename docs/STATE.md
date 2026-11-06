# Sunset — state of the implementation (handoff)

Last updated 2026-11-05. A new session reads this, `AGENTS.md`, the open tasks and notes, and carries on. The ADRs say why; the diary is the log.

## What exists

- **Docs/research/probes**: ADRs 0001–0023, roadmap 0001–0016, competitor baseline (`bench/`), probes in `Benchmarks/` (VT cell-format model, cold history, handoff, Metal read).
- **Code (new)**: `Package.swift` with `SunsetCore` (platform-free, strict settings, no dependencies) and `SunsetCoreTests`.
  - `Sources/SunsetCore/Parser`: `VTParser` (byte state machine, ADR-0023), `VTSink`, `Parameters`, `Intermediates`, `ParseCounter` (concrete front for other modules).
  - Tests: `swift test -c release --enable-testable-imports` → 24 pass (directed + seeded property tests).
  - Benchmarks: `Benchmarks/Benchmarks/ParserBenchmarks` (`cd Benchmarks && swift package benchmark --no-progress --target ParserBenchmarks`); baseline in `bench/results/2026-11-05/parser-baseline.txt`.

## Measured (instructions per 1 MiB, p50, release; 0 mallocs on all)

ASCII text 11 M · UTF-8 text 44 M · OSC titles 21 M · cursor moves 81 M · truecolor SGR 87 M.

## Next

1. Screen model behind the sink: grid of 8-byte cells with page-local styles (ADR-0012, proposed), cursor, wrap, scroll, erase, SGR, tabs, alternate screen; red tests from `esctest` fixtures and the gap list.
2. Replies and modes (DA, DSR, DECRQM, XTVERSION, OSC colour queries), kitty keyboard flags, mouse modes, synchronized output.
3. Parser cost on CSI (profile, then change), vector ASCII path (probe T0.4), `esctest`/`vttest` and oracle differential runs (kitty, ghostty, wezterm as processes).
4. Probes 6 (frame scheduling) and 7 (reflow, backpressure) of roadmap 0002; PTY host; renderer later.

## Not established

C1/limit policies unchecked against oracles; CSI cost unexamined; no screen yet; ADR-0012 (cell) and ADR-0005 (colour) still proposed.
