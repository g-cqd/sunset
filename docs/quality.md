# Quality rules, consolidated

Owner notes n3 and n4 (2026-11-06): be very strict on safety, and bring the quality rules of every repository into this one. This is the list, where each rule
comes from and what enforces it. Everything here fails the pre-commit hook, `swift test` or CI; nothing is advice.

| Rule | Source | Enforced by |
|---|---|---|
| No `!` force unwrap, no `try!`, no `as!` (in Sources, Tests and tools) | swift-ci `quality.discipline` (aemi's `swift package lint`); owner n3 | `.swift-format` (`NeverForceUnwrap`, `NeverUseForceTry`), `.swiftlint.yml` (`force_unwrapping`, `force_try`, `force_cast`) |
| No implicitly unwrapped optionals | owner n3 | `.swift-format` (`NeverUseImplicitlyUnwrappedOptionals`), `.swiftlint.yml` (`implicitly_unwrapped_optional`) |
| `fatalError` carries a message; no `unowned` captures | owner n3 | `.swiftlint.yml` (`fatal_error_message`, `unowned_variable_capture`) |
| Contract violations are `precondition`s with a sentence, never silent clamps | white paper §4 | review; used at constructors (`Screen`, `Surface`, `RenderMetrics`, `Palette`) |
| Swift 6 language mode, strict memory safety, `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, warnings are errors | white paper §4 | `Package.swift` `strictSettings` (every target) |
| Swift 6.4.2 | owner, 2026-11-06 | `.swift-version`, `.ci/action.json` |
| Function body 60 lines (error 80), type body 200 (error 400), file 300 (error 500), cyclomatic complexity 10 (error 15), tuples of 3, 6 parameters, nesting 3/5 | ask's `.swiftlint.yml`, the strictest in the family (the canonical file allows 80/300/500/15) | `.swiftlint.yml` |
| One top-level type per file, named for it (`Type+Feature.swift` for extensions); no file past 250 lines, tests included; `@Suite` structs count; generated files exempt | ask ADR-0021, AemiFormal ADR-0004 (`SourceStructureTests`) | `SourceStructureTests` inside `swift test` |
| No `strtod`; no hand-rolled PRNG in tests (use AemiTestKit's `SeededRNG`); `#expect(throws:)` names its error; no wall-clock assertions | swift-ci `quality.discipline` | CI (`.ci/action.json` `quality.discipline`); `SeededRNG` is used throughout |
| No Grand Central Dispatch (`import Dispatch`, `DispatchQueue`, `DispatchSource`, `DispatchSemaphore`, ...): Swift concurrency and executors only | owner n7 | `BannedAPITests` inside `swift test` |
| Red first; a performance claim has a measurement; mutation testing in CI only; never wait on CI; restore mutants from a copy, never `git checkout` | white paper §1 | process; `.github/workflows/mutation.yml` |
| Documentation law, `// lint:allow` only with a reason on the line | swift-ci | CI |

## Not yet enforced (owed)

- (Done) every target, the executables included, is in Swift 6 language mode with the strict settings.
- No check that every public declaration is documented beyond swift-format's `AllPublicDeclarationsHaveDocumentation` (off in the family's file).
- The other analyzers the family runs (deadwood, dolly, arcleak, fcheck: see TerminalKit's `Scripts/quality.sh`) are not wired here; swift-ci runs the ones in `.ci/action.json` once the repository is pushed.
