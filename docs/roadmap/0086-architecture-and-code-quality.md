---
status: in-progress
blocked-by: nothing
date: 2026-11-19
---

# 0086 — Architecture, separation of concerns, duplication, formatting, tasks and time (the owner's note n55, first)

The owner, 2026-11-19: "the app architecture, the modules architectures, overall structures, separation of concern and
duplicated codes are very bad … a lot of single line variable/method definition … i'd prefer that we span multiple lines …
we spawned a lot of unstructured tasks or sleep without relying on taskprovider or clock". Prioritised before everything
else in roadmap 0058. Rules: ADR-0087.

## Measured at ba46005 (Sources unless said)

| What | Count |
|---|---|
| One-line bodies of a `func`, `init`, computed `var`, accessor | 694 (Tests 87) |
| `Task {` / `Task.detached` / `Task.sleep` | 82 / 5 / 38, none through a seam |
| `ContinuousClock.now` / `Date()` read directly | 23 / 33 |
| dolly's clones | 215 (near 168, exact 35, structural 12); SunsetConfig 91, SunsetShell 35, SunsetWeb 21, SunsetApp 17 |
| A setting written | 5 times: `Configuration`, its reader, its writer, `ConfigurationKeys`, its `SettingsOption` |
| SunsetShell | 262 files: the window's model (105 files with no UI import) and its views in one module |
| SunsetApp | 155 files, 17 Sunset modules imported, no tests |

## Stages, in order

| # | What | Gate that holds it | Status |
|---|---|---|---|
| A | Formatting: no one-line bodies; every `func`, `init`, computed `var`, accessor and observer spans lines | `SourceShapeTests` (red: 938 found; green: 0); `Scripts/tools/expand-one-line-bodies.py` | done: 948 spanned in 432 files; five files past 250 lines split by concern |
| B | Tasks and time through seams: `Runtime` (SunsetRuntime: a `TaskProvider`, an `any Clock<Duration>`, `uptime`, `now`) for every task, sleep and read of the time; tests with `TaskProviderSpy` and `TestClock` (AemiTestKit) | `UnseamedTimeTests`: raw `Task {`, `Task.detached`, `Task.sleep`, `ContinuousClock`, `Date()` in Sources outside `Runtime.swift`, a count that only goes down | Sources done: 181 to 0 (red observed at 181); `CloseConfirmation`, `HoverReveal`, `SurfaceRing` measure in `Duration`; the manifest's plain targets through `module(…)` and `tests(…)` (313 to 189 lines). Tests done: Sunset's own timing on `TestTime` (autosave, icon library, frame rest, window lights, drag watch); what is not Sunset's through `RealWait` and `Stopwatch`; gated over Tests too. Not done: a test's own `Task {}` for concurrency stays (allowed by the gate) |
| C | One declaration per setting: its `SettingsOption`, whose control reads and writes the file (`SettingCodec`), from which the reader, the writer, the key list and the profile keys are made | `SettingCodecTests`: a codec key spelled once in SunsetConfig's code (red: 102; green) | done for toggles, numbers and choices (95 keys); texts, colours, lists, the layout measures and themes stay by hand (61 keys). SunsetConfig −233 lines, clones 91 → 63 |
| D | Modules by concern: SunsetShell's model (tabs, Spaces, Favorites, keep-awake, commands) apart from its views; SunsetApp's logic into modules with tests, the app target only wiring | `ModelLayerTests` (no UI import in SunsetShellModel; the content contract in it) | SunsetShellModel done (116 files; the contract freed of SwiftUI and AppKit). SunsetAppCore begun (`LaunchOptions`, `ClearSpan`, `PageSettingsMaker`, the window's configuration; `AppDecisionsTests`). Not done: the rest of SunsetApp's logic (the `App*` singletons: storage, blocking, keeping, spaces), which needs their state injected first; SunsetWeb and SunsetTerminal each mix model and views too |
| E | Clones to zero: dolly's baseline emptied, module by module | dolly with no baseline | not-started |

Not done: everything; this entry is updated as each stage lands, with the counts again.
