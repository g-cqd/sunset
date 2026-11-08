# What of `aemi` can be dropped (owner note n17, 2026-11-08)

Method: `swift package dump-package` on `g-cqd/aemi` (56 targets, 29 products, commit e30aad8) for the target graph; every `Package.swift` under `/Volumes/Personal/Github/g-cqd` for the products each project declares from `aemi`; `import` lines for what is actually used. Transitive dependencies are followed. "Family" = the packages named `Aemi*` (AemiHMMML, AemiHTML, AemiJSON, AemiMarkdown, AemiMermaid, AemiProtobuf, AemiRegex, AemiSDR, AemiSwift, AemiUI, AemiUtilities) plus `sunset`. Kept on the owner's word: `AemiSDR` (a package of its own, which only needs `InternedStrings`) and `InternedStrings` (with the `AemiMacros` it is built on).

**Limits.** Only the projects checked out under `g-cqd` were read; repositories of the Aemi-Studio organisation that are not here were not. This is at the level of modules and products; dead *symbols* inside a module we keep (for example inside `AemiKernel`, 5 680 lines) are not found yet. Nothing was deleted anywhere.

## Cannot be dropped (the family needs it, directly or through another module)

| Module | Lines | Used by (family) |
|---|---:|---|
| AemiKernel, AemiKernels, CAemiKernels, CAemiCPU | 5 680 + 1 314 + 4 020 + 369 | HMMML, HTML, JSON, Markdown, Mermaid, Protobuf, Regex, sunset |
| AemiTestKit, AemiTestKitSeams, CAemiTestKitMalloc | 3 165 + 9 + 126 | HMMML, HTML, JSON, Markdown, Mermaid, sunset (tests) |
| AemiRuntime | 691 | HMMML, HTML, JSON, Markdown, Mermaid, Regex (and AemiTestKitSeams needs it) |
| AemiUnicode | 5 504 | Regex; HMMML through AemiText |
| AemiText | 403 | HMMML |
| AemiMetrics | 307 | Mermaid (one `import`); AemiJSON declares it but does not import it |
| AemiInterner | 693 | Mermaid |
| AemiMacroSupport | 99 | JSON |
| AemiCore, AemiUI, AemiTesting | 1 393 + 1 407 + 1 837 | AemiSwift, AemiUI, AemiUtilities |
| InternedStrings, AemiMacros | 197 + 543 | AemiSDR, sunset (kept as asked) |

## Can be dropped

Only non-family projects use these (they lose the API, which the owner accepts):

| Module | Lines | Only used by |
|---|---:|---|
| AemiDiff | 3 081 | ask, ask-questions, ask-sweep |
| AemiLexers | 2 261 | ask, ask-questions, ask-sweep |
| AemiIO | 1 962 | ask*, analyzerkit, litmus (AemiFileSystem needs it) |
| AemiArgon2 + CAemiArgon2 | 339 + 932 | ask* |
| AemiFileSystem | 546 | analyzerkit, litmus |
| AemiProcess | 318 | analyzerkit |
| AemiDigest | 61 | analyzerkit, litmus (the only user of `Crypto` in the package) |

Nobody depends on these: `Aemi` (4 lines, the umbrella), `AemiFoundation` (16, re-exports IO, Process, Text and others), `Loggable` (27, and the `Loggable` macro in `AemiMacros` with it, if `InternedStrings` does not use it), the executables `AemiCodecProbe` and `AemiKernelsProbe` (481), and the `AemiKernelsFuzz` product (kept only behind a flag).

Total that goes: about 10 000 lines (9 500 + 530; the C targets included) of about 38 000 in `Sources/`, plus their tests, products and the `Crypto` dependency. If `ask` (this agent) must keep building, it needs a local copy or a pin of the current revision of the seven modules above.

## To check before deleting

1. `AemiTesting` and `AemiCore`/`AemiUI` are kept because `AemiSwift`, `AemiUI` and `AemiUtilities` declare them; if those three are not in the focus, 4 600 more lines go.
2. Declared but not imported: `AemiJSON` lists `AemiMetrics` and no source or test imports it. A full declared-versus-imported comparison for every project was not made.
3. The symbol-level pass (which public API of `AemiKernel`, `AemiUnicode`, `AemiTestKit` the family uses) would need the compiler's index store of each project; not done.
4. `Benchmarks/`, `development/`, `Plugins/` (Format, Lint, LintBuild), `Scripts/`: not looked at.

## Sunset's own structure (the other half of n17)

| Target | Lines | Depends on |
|---|---:|---|
| SunsetCore (parser, screen, input) | 4 118 | nothing |
| SunsetApp (all UI, models, tabs, settings) | 3 589 in 62 files | everything |
| SunsetConfig | 1 515 | AemiJSONCore |
| SunsetRender / SunsetRenderMac | 1 498 / 272 | Core (+C kernels) |
| SunsetHost (session, pty) | 1 088 | Core, **Config** |
| SunsetRun, SunsetRenderTool, SunsetPrivate | 171, 105, 111 | |

Problems seen: `SunsetApp` is an executable, so none of its 3 600 lines can be imported by a test (this is why the tab-switch fix of the same day has no regression test); `SunsetHost` depends on `SunsetConfig`, so the session knows the file format; the terminal view, the tab model, the settings and the window chrome sit in one target with no boundary. Proposal for discussion: `SunsetUI` library (everything in `SunsetApp` except `@main`), split by what it is: `SunsetPane` (the content of a tab as a protocol: terminal now, web page later), `SunsetTabs` (tab list, spaces, registry), `SunsetChrome` (window, sidebar, lights), `SunsetSettings`; `SunsetHost` freed from `SunsetConfig`. The executable stays a few lines. This also is the shape the web-page pane (n19) needs.

## Erratum (2026-11-08, same day)

The owner said this audit was wrong, and it was. The "Cannot be dropped" and "Can be dropped" tables above must not be used:

- It was written against the local `aemi` checkout (`e30aad8`); the remote `main` is `0bae2ed` (three commits more, including `AemiLexers` TLA+/Lean for AemiFormal).
- It read only the top-level `Package.swift` of each project. Nested manifests (Atelier's apps, MacFS, MarkdownLook, tools) were not read. `AemiDiff`, `AemiIO` and `AemiLexers` are used by Atelier; `AemiIO` by MacFS; `AemiLexers` by MarkdownLook; AemiFormal plans to use `AemiIO`, `AemiDigest` and `AemiLexers`.
- It treated `AemiUI`, `AemiSwift` and `AemiUtilities` as the family that keeps `AemiCore`, `AemiUI` and `AemiTesting` alive. They are zero-code re-export shims, and `AemiUI` (the module) has no consumer at all.

The corrected report is `~/Public/aemi-ui-swift-utilities-report-2026-11-08.md`.
