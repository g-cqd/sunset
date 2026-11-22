# Sunset — the state of the code (2026-11-22)

Facts measured from the repository on 2026-11-22: 726 commits; the latest release is v0.1.0-alpha.8 (`docs/releases/`).
Why things are as they are is in `docs/adr/`; what is intended is in `docs/design/`; the rules every change follows are in
`docs/WHITE-PAPER.md` and `docs/quality.md`.

## What Sunset is

A terminal emulator for macOS, written in Swift, whose window also holds web pages and documents as tabs and panes:

- **Terminal**: a platform-free core (parser, screen, modes, replies) fed by a program on a pseudo-terminal, drawn by a CPU
  renderer or a Metal one that replays its draw list.
- **Web**: pages on the system's WebKit, with history, downloads, per-site permissions, content blocking, private windows,
  WebKit's extensions, and a choice of the browser a site is shown.
- **Documents**: Markdown, Mermaid and text, drawn natively or as source, either a file of the person's or a document that
  lives in Sunset's sealed store; a change on disk is merged block by block.
- **The window**: tabs in a sidebar, a built-in bar or the system's tabs; splits; Spaces, each with a profile; Favorites and
  a Pinned grid per profile; the Library (history, documents, downloads); a command bar.
- **What it keeps**: sealed records in one state database, sealed documents, WebKit's cookie jars and sites' storage sealed
  while Sunset is closed; the key in the data-protection keychain, wrapped by the Secure Enclave.

Two builds are released, both signed with Developer ID and notarised: **Sunset**, on macOS's WebKit, and **Sunset WebKit**,
on a WebKit of its own (`Scripts/webkit.sh`, `Scripts/make-webkit-app.sh`). They share Sunset's store, settings and key; one
runs at a time.

## The targets

| Target | Swift files | Lines | What it is |
| --- | ---: | ---: | --- |
| `SunsetCore` | 87 | 5,042 | The headless emulator: VT parser, screen, modes and replies. Platform-free |
| `SunsetHost` | 26 | 1,320 | A program on a pseudo-terminal feeding the core, with no window; the only core target that imports the platform |
| `SunsetRender` | 38 | 2,183 | The CPU renderer: cells to pixels, the reference the GPU renderer is held to. Platform-free |
| `SunsetRenderMac` | 10 | 569 | The macOS glyph source (CoreText) and the surfaces a window shows |
| `SunsetRenderMetal` | 7 | 683 | The Metal renderer: replays the CPU renderer's draw list on the GPU |
| `CSunsetKernels` | — | — | Pixel kernels in C with NEON and a scalar fallback, each tested against its scalar reference |
| `SunsetTerminalModel` | 26 | 1,149 | The terminal's model: session, screen, renderer's wiring, selection, links. No AppKit, no SwiftUI |
| `SunsetTerminal` | 14 | 677 | The terminal as a kind of pane content: its AppKit view, keys and mouse |
| `SunsetPane` | 64 | 3,127 | What a window holds: panes in splits, tabs, Spaces, Favorites. Pure values, no UI |
| `SunsetShellModel` | 133 | 6,941 | The window's model: tabs, Spaces, Favorites, sidebar sections, commands. No UI framework |
| `SunsetShell` | 181 | 7,926 | What shows the window's model (SwiftUI, AppKit) |
| `SunsetShellBridge` | 3 | 59 | Joins the configuration file to the shell's settings |
| `SunsetWebModel` | 71 | 3,038 | The web's policy: site rules, permissions, history, how sites see Sunset, search, downloads. No WebKit, no UI |
| `SunsetWeb` | 117 | 7,886 | Web pages (WebKit) and what shows them |
| `SunsetSiteData` | 5 | 244 | The Public Suffix List and Apple's password-manager-resources, with their readers |
| `SunsetDocuments` | 32 | 1,784 | Sunset's document store, and the one document behind every pane on a file or a stored document |
| `SunsetMarkdown` | 21 | 1,130 | A document as a kind of pane content: Markdown and Mermaid drawn natively or as source |
| `SunsetConfig` | 84 | 4,464 | The configuration file: schema, defaults, validation, Settings' sections. Platform-free |
| `SunsetStorage` | 40 | 2,280 | Where everything Sunset keeps is, sealed, written whole or not at all; the keys; WebKit's folders |
| `SunsetCredentials` | 11 | 474 | Password management's model: vault files, factors (master password, Touch ID, recovery code), the lock. No UI |
| `SunsetImport` | 29 | 978 | Another browser's bookmarks, profiles and more, read and turned into Sunset's. No UI |
| `SunsetHelp` | 9 | 437 | Help's topics and texts, one source for a control's tooltip and its explanation |
| `SunsetPrivate` | 17 | 661 | Private API looked up by name at run time (window blur, WebKit's find, permissions, audio) |
| `SunsetRuntime` | 1 | 74 | Tasks and time through seams: what every module is given, live in the app, a test's own in tests |
| `SunsetMetrics` | 1 | 63 | The interface's measures (`layout.*`): one list, read by the configuration and drawn by the shell |
| `SunsetAppCore` | 21 | 784 | What the app decides, apart from what it shows. No UI framework |
| `SunsetApp` | 206 | 12,686 | The app: scenes, menus, settings, the glue between the targets |
| `SunsetAppMain`, `SunsetRun`, `SunsetRenderTool` | 3 | 245 | The executables: the app's entry, `sunset-run` (a program's screen as text), `sunset-render` (as a PNG) |

Tests: 615 files, 1,980 tests, in 19 test targets, all passing with `swift test` on 2026-11-22.

## How it is checked

- At every commit: swift-format, SwiftLint, the structure rules (one top-level type per file, 250 lines a file), no
  unseamed time or tasks, no Grand Central Dispatch (`docs/quality.md`).
- `swift test`: 19 test runs, no warnings.
- CI (`.ci/action.json`): the same, plus deadwood, dolly and arcleak against their baselines; mutation testing once a day.
- Benchmarks: ordo-one in `Benchmarks/`, release only, against the oracles where a comparison exists.
