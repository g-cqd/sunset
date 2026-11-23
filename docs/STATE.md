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

## Priorities (rescheduled 2026-11-22)

The owner asked for performance, security, safety and memory first, and native, quiet interfaces; his latest note (n94) is
images in the terminal. The tasks carry the band as a tag (`p1-now`, `p2-next`, `p3-screen`, `p4-later`, `owner`,
`elsewhere`), in this order.

1. **Now**
   - Terminal images (n94, ADR-0117, roadmap 0010): kitty graphics in the core, then drawn; Sixel and iTerm2 after.
   - The parser fuzzed (roadmap 0026 T-8): every byte a program prints is untrusted, and images add a new parser; the
     fuzzer covers both.
   - Tab switching speed (n56, n59): measured in release first; mbp23's patch (`docs/research/patches/`) read again.
   - Performance and memory (n11): a measured pass over idle memory, a page's, a terminal's scrollback, the vault's.
2. **Next**
   - WebKit's data at rest beyond the cookie jar (A4); the vault's imports and backups (0095), then its open steps
     (0091 E, 0092 B–F, 0093 C–F, 0094 F); the architecture's ratchets (n55).
   - The terminal's open ends (0026): scrollback search, bash integration, fonts per style, OSC 21, the esctest and
     vttest gaps, shaping's cost.
   - Restoring the running state (0024, n46).
3. **With the owner, on screen**: drag and drop (n79, n80, n84/n85), Now Playing, and what only tests have seen.
4. **Later**
   - Markdown's tools (0023 M-g to M-i); commands, keys, App Intents and remote control (0027, n1).
   - Network and engine (0046, 0048); Safari's missing APIs; the vault's sync, hardware keys, passkeys and payments.
   - The interface notes (n50, n51, n53–n55, n57, n60, n66, n68); the studies; CI; one app with a downloadable engine
     (0113); WebKit's speed (0110) last, as asked.
5. **The owner's**: the white paper as AGENTS.md; the family's history purge and repins.
6. **Elsewhere**: the TUI framework's tasks (from mbp23), the harness's, AemiSDR's iOS slices.

## Paused (2026-11-23)

Work paused at the owner's request (no access to mbp23, which signs and pushes, for the rest of the day).

- **Published**: main at 49386279 on GitHub; release v0.1.0-alpha.11 (build 786), both apps installed from the
  downloaded copies.
- **Local only**: everything after 49386279 (work goes on locally the rest of the day, unpushed). 1279b224 (audit MEM-06)
  was checked afterwards: the full suite, the quality gate, the release build pass; clones 133.
- **To resume**: push through mbp23 with its key unlocked (`~/.local/share/sunset-agent/push.sh N`, which
  refuses to start when the key is locked: it bundles `origin/main..HEAD`, rebases and signs
  on mbp23, pushes, and resets here only once mbp23's main has the same changes).
- **Next** (tasks): the vault fields' editing sheet (t334), the vault's cards (t318), the recovery code window closing
  with Touch ID on (t333, mitigated), `.xpi` signatures (t305), the remaining audit tasks (t304, t307–t314), Sunset WebKit
  kept up to date on a schedule (t335, roadmap 0115).
- **Next release (alpha.12) adds a step**: after `package-release.sh` and the WebKit app, run
  `Scripts/make-update-packages.sh <zip> 3` for each zip, and upload the `.update` files and their `.sha256` with the
  zips (the `upN.sh` on mbp23 must take `*.update*` too). alpha.12 is the first build that updates itself; it can only
  be seen doing so once alpha.13 is out (roadmap 0122).

## On hold (2026-11-23, 17:05)

- **Local only**: 29 commits after GitHub's main (49386279); none pushed (mbp23 unavailable). The tip builds and passes
  the gates. The web tests timed out under another project's load (load average 40–215), alone too; not re-run since.
- **Installed**: 818 for both apps (notarized). Later commits are not installed: the tab menu's symbols, Share no longer blue
  (n139, n140); Passwords in every window's Library (n141); the engine as a downloadable component (roadmap 0113 C, D in
  part). The 818 → next build was stopped mid-build on purpose.
- **Tab menu symbols**: the owner chose every item's (done, not installed). **Waiting for the owner**: whether passwords
  now save as expected (t346).
- **To look at**: three web tests on a local server (`BrowserAgentTests` ×2, `HTTPSUpgradeAskTests`) fail in every full
  run since mid-afternoon, pass alone.
- **Next**: n142 (icon previews, Auto icon by time of day), n143 (welcome animation by time of day); roadmap 0113: publish an
  engine (`make-engine-archive.sh`) and see it downloaded, switched, deleted end to end; roadmap 0122 alpha.12 release step.

## Release routine from alpha.13 (ADR-0125)

1. `Scripts/package-release.sh vX DIST` (the native zip), then `SUNSET_SIGN_HOST=<signing Mac> Scripts/package-variants.sh vX DIST docs/releases/vX.md`:
   the WebKit variant (same `Sunset.app`, `studio.aemi.sunset`) notarized and zipped, one `.deltas` archive per variant
   (the last three builds of the same app, and the other variant at this build), checksums, and the signed
   `release-index.json` + `.sig` (Ed25519, key on the signing Mac only). The notes signed must be the file given to
   `gh release create`, byte for byte.
2. Upload: both zips, both `.deltas`, every `.sha256`, `release-index.json`, `release-index.json.sig`.
3. The CI release workflow signs the index only when the `RELEASE_INDEX_KEY` secret (the main key, base64) is set; not set
   today.
- alpha.12's updater cannot read `.deltas`: it falls back to the zip. Sunset WebKit alpha.12 (`studio.aemi.sunset.webkit`)
  will refuse the new WebKit variant (another identifier): its users install Sunset and switch the engine in Settings; the
  alpha.13 note must say so.
