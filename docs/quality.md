# Quality rules, consolidated

Very strict on safety, with the quality rules of every repository of the family brought into this one (2026-11-06). This is the list, where each
rule comes from and what enforces it. Everything here fails the pre-commit hook, `swift test` or CI; nothing is advice.

| Rule | Source | Enforced by |
|---|---|---|
| No `!` force unwrap, no `try!`, no `as!` (in Sources, Tests and tools) | swift-ci `quality.discipline` (aemi's `swift package lint`); project rule | `.swift-format` (`NeverForceUnwrap`, `NeverUseForceTry`), `.swiftlint.yml` (`force_unwrapping`, `force_try`, `force_cast`) |
| No implicitly unwrapped optionals | project rule | `.swift-format` (`NeverUseImplicitlyUnwrappedOptionals`), `.swiftlint.yml` (`implicitly_unwrapped_optional`) |
| `fatalError` carries a message; no `unowned` captures | project rule | `.swiftlint.yml` (`fatal_error_message`, `unowned_variable_capture`) |
| Contract violations are `precondition`s with a sentence, never silent clamps | white paper §4 | review; used at constructors (`Screen`, `Surface`, `RenderMetrics`, `Palette`) |
| Swift 6 language mode, strict memory safety, `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, warnings are errors | white paper §4 | `Package.swift` `strictSettings` (every target) |
| Swift 6.4.2 | project rule (2026-11-06) | `.swift-version`, `.ci/action.json` |
| Function body 60 lines (error 80), type body 200 (error 400), file 300 (error 500), cyclomatic complexity 10 (error 15), tuples of 3, 6 parameters, nesting 3/5 | ask's `.swiftlint.yml`, the strictest in the family (the canonical file allows 80/300/500/15) | `.swiftlint.yml` |
| One top-level type per file, named for it (`Type+Feature.swift` for extensions); no file past 250 lines, tests included; `@Suite` structs count; generated files exempt | ask's and AemiFormal's structure rules (`SourceStructureTests`) | `SourceStructureTests` inside `swift test` |
| No `strtod`; no hand-rolled PRNG in tests (use AemiTestKit's `SeededRNG`); `#expect(throws:)` names its error; no wall-clock assertions | swift-ci `quality.discipline` | CI (`.ci/action.json` `quality.discipline`); `SeededRNG` is used throughout |
| No Grand Central Dispatch (`import Dispatch`, `DispatchQueue`, `DispatchSource`, `DispatchSemaphore`, ...): Swift concurrency and executors only | project rule | `BannedAPITests` inside `swift test` |
| Red first; a performance claim has a measurement; mutation testing in CI only; never wait on CI; restore mutants from a copy, never `git checkout` | white paper §1 | process; `.github/workflows/mutation.yml` |
| Documentation law, `// lint:allow` only with a reason on the line | swift-ci | CI |

## Not enforced

- No check that every public declaration is documented beyond swift-format's `AllPublicDeclarationsHaveDocumentation` (off in the family's file).
- Of the analyzers the family runs, fcheck is not wired here; swift-ci runs deadwood, dolly and arcleak (`.ci/action.json`), each against its baseline in
  `.ci/baselines/`, and `CloneRatchetTests` keeps dolly's count from rising.
