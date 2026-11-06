# Sunset — state of the implementation (handoff)

Last updated 2026-11-05 (screen v1). A new session reads this, `AGENTS.md`, the open tasks and notes, and carries on. The ADRs say why; the diary is the log.

## What exists

- **Docs/research/probes**: ADRs 0001–0023, roadmap 0001–0016, competitor baseline (`bench/`), probes in `Benchmarks/` (VT cell-format model, cold history, handoff, Metal read).
- **Code (new)**: `Package.swift` with `SunsetCore` (platform-free, strict settings, no dependencies) and `SunsetCoreTests`.
  - `Sources/SunsetCore/Parser`: `VTParser` (byte state machine, ADR-0023), `VTSink`, `Parameters`, `Intermediates`, `ParseCounter` (concrete front for other modules).
  - `Sources/SunsetCore/Screen`: `Terminal` (parser + screen, `feed`), `Screen` (the sink: grid, cursor, modes, regions, SGR, alternate screen, dirty rows), `Cell` (8 bytes), `CellStyle`, `StyleTable`, `Grid` (ADR-0025).
  - Dependency: `TerminalKitText` (display widths) from g-cqd/TerminalKit by revision `5966813`; ADR-0002 accepted: g-cqd and Aemi-Studio packages freely, Apple/swiftlang on approval.
  - Tests: `swift test -c release --enable-testable-imports` → 160 pass (150 core + 10 host) (parser, properties, screen, differential against a naive model, replies and modes).
  - Replies: `Terminal.takeReplies()` (bounded queue, ADR-0026); `Screen.modes` (what the host needs), `keyboardFlags`, `cursorShape`.
  - Benchmarks: `Benchmarks/Benchmarks/ParserBenchmarks` (`cd Benchmarks && swift package benchmark --no-progress --target ParserBenchmarks`); baseline in `bench/results/2026-11-05/parser-baseline.txt`.

  - `Sources/SunsetHost` (the platform seam): `PTYProcess`, `HeadlessSession`; `Sources/SunsetRun` (`sunset-run`, prints a program's screen); `Scripts/oracle-compare.sh` + `Scripts/oracle-streams/*.sh` (15 streams, all equal to kitty's text, ADR-0030).

## Measured (instructions per 1 MiB, p50, release; 0 mallocs on all)

Parser alone: ASCII 11 M · UTF-8 44 M · OSC 21 M · cursor moves 81 M · SGR 87 M.
Terminal (parser + screen, 120x40): ASCII 50 M · cursor moves 142 M · OSC 102 M · SGR 153 M · UTF-8 268 M. Results in `bench/results/2026-11-05/`.

## Next

1. Replies and modes (DA1/DA2, DSR/CPR, DECRQM, XTVERSION, OSC 4/10/11/12 queries), OSC titles/hyperlinks, DECSCUSR, soft reset, kitty keyboard flags, mouse modes, synchronized output.
2. Cold compressed history (ADR-0013), left/right margins. Done since: grapheme clusters (ADR-0029), charsets, scrollback ring, resize with reflow (ADR-0028).
3. Widen the oracle comparison: styles and cursor, replies, resize, ghostty and wezterm; `esctest`/`vttest` fixtures with a published gap list; fuzzing; profile the CSI path.
4. Renderer seam (ADR-0024, proposed): CPU renderer first, then Metal, a runtime toggle `auto|gpu|cpu`, pixel differential as the first gate. Probes 6 and 7 of roadmap 0002; PTY host.

## CI (not yet run on GitHub)

`.github/workflows/ci.yml` (swift-ci) and `mutation.yml` (daily, CI only; script `Scripts/mutate-changed.sh`), `.ci/action.json`. Mutation testing is not run locally (white paper §1); nothing is pushed, so none of it has run.

## Not established

C1/limit policies and the screen's behaviour are unchecked against oracles; no speed comparison with other terminals; ADR-0012 (cell) and ADR-0005 (colour) still proposed; ADR-0024 proposed, no renderer yet.
