# The threat model against the state of the art (2026-11-21)

Task t136: the owner asked (2026-11-20) for the threat model (docs/design/0006) to be hardened against current research in
each field Sunset touches. What the sources say is theirs, cited; what Sunset does was read in its code or measured on this
Mac, and says so. Claims stay claims until probed.

## 1. The web engine

| Source | What it says | Sunset |
|---|---|---|
| Chromium, *Site Isolation* (chromium.org, read 2026-11-21) | A browser's threat model must include a **compromised renderer**: exploitable bugs appear every release ("10 potentially exploitable bugs in renderer components in M69, … 15 in M73"); UXSS bugs are common; Spectre reads a process's memory without any bug. Chrome puts every site in its own process, frames included, since Chrome 67/77 on desktop, at a cost of "about 10-13%" memory (Chrome's figures) | WebKit main of 2026-11-21 (our base): `SiteIsolationEnabled` is `unstable`, default **off**; `ProcessSwapOnCrossSiteNavigationEnabled` `stable`, on. Read in `UnifiedWebPreferences.yaml`. So a top-level navigation to another site changes process, but **a cross-site frame shares its embedder's process** in both builds. A10 (a compromised WebContent) reads what every frame of its page holds |
| WebKitGTK security advisories (webkitgtk.org, read 2026-11-21), which republish Apple's WebKit fixes | 10 advisories in 2025, 7 in 2026 so far: one every 5–7 weeks. WSA-2026-0007 (18 November 2026): **26 CVEs**, 10 of them "may lead to arbitrary code execution", one "a remote attacker may be able to break out of Web Content sandbox" | Sunset (the system's WebKit) gets them with macOS updates. **Sunset WebKit gets none from macOS**: it is safe only as long as it is rebuilt on a WebKit at least as new as the last advisory. Our update takes < 90 s to apply and ≈61 min to build (diary 2026-11-21-10); the risk is the delay between an advisory and a release, not the work |
| Apple, *Allow DYLD environment variables entitlement* (developer documentation) | The entitlement lets `DYLD_*` variables change what the loader does; an injected library still needs "the Disable Library Validation Entitlement if an injected library isn't signed with the expected team ID" | Sunset WebKit has the entitlement and keeps library validation (read with `codesign -d --entitlements`). At launch it replaces every loader variable with its own frameworks and removes inserted libraries, then runs itself again (`BundledWebKit`). **Gap**: in that first instant, before the restart, the frameworks of the launcher's choosing are loaded and their initialisers run, limited by library validation to Apple's or our team's (an older Sunset WebKit release's WebKit, with its known bugs, qualifies). Sunset (native) honours no loader variable (hardened runtime, no exception) |

## 2. Extensions and filling

| Source | What it says | Sunset |
|---|---|---|
| M. Tóth, *DOM-based Extension Clickjacking*, DEF CON 33 (9 August 2025, updated 14 January 2026) | Extensions that draw their UI **inside the page's DOM** (a fill menu) can be made invisible by the page (`opacity`, overlays, the Popover API's top layer) and clicked through a fake cookie banner. 11 password managers' extensions tested; all vulnerable by default; "10 out of 11" leak credentials with one click once the attacker runs script on any subdomain, since all fill **subdomains** of the saved domain. His mitigations: closed shadow roots, watching for overlays; "doesn't exist simple protection"; a platform-level fix is needed | Sunset's own fill (planned, ADR-0094) draws its suggestions **outside the page**, in Sunset's window: the technique does not reach it. To keep: exact-origin matching by default (not subdomains), the person's act on Sunset's UI, never a click on the page. Extensions the person installs (password managers among them) are as exposed in Sunset as in Chrome or Firefox |
| ADR-0112 (ours) | Our WebKit lets an extension with blocking `onHeadersReceived` rewrite a document's response headers; names and values are checked for well-formedness only | An extension granted a site can remove its `Content-Security-Policy`, `X-Frame-Options`, change `Set-Cookie`: what Firefox allows too. The threat model's row "an extension oversteps: its policy table before the first extension" is **stale**: extensions run, the table is not written |

## 3. The terminal

| Source | What it says | Sunset (read in `SunsetCore` and ADR-0010/0026/0027) |
|---|---|---|
| D. Leadbeater, *ANSI Terminal security in 2023 and finding 10 CVEs* (dgl.cx, October 2023; DEF CON 31) | Classes: misuse of sequences (hiding text), **echoback** (a reply the attacker shapes lands in the shell's input: title reports, DECRQSS, OSC 50 font queries; CVEs in iTerm2, mintty, SwiftTerm, xterm, ConEmu), parser overflows (Sixel, ReGIS), unescaped processing (Windows Terminal OSC 9;9, rxvt's Perl eval, kitty's notification OSC), DoS (REP, title floods), leaks (OSC 52 read, DECRQCRA cursor checksums, **Terminal.app's DNS lookup on OSC 7**). Recommends exact VT100 parsing and **not** accepting C1 controls inside UTF-8 ("I cannot recommend" terminals that do) | Title reports, OSC 52 read, pixel sizes: never answered; DECRQSS, XTGETTCAP, OSC colour queries, DECRQCRA: not implemented, so not answered; replies a bounded queue (64 KiB); OSC 7 parsed, never reported, **no lookup** (the host compared to the local name only when a link is opened by Command-click); notifications bounded and stripped; REP capped at 65,535 repeats a sequence (`Screen+Edit`); Sixel and ReGIS not implemented. **Gap: C1 controls inside UTF-8 act as controls** (`VTParserStringTests`: U+009B is CSI), as in kitty, VTE, WezTerm |
| Same, on pastes | Bracketed paste can be escaped by a paste containing the end marker | The end marker is stripped from pastes (ADR-0010); `PasteRisk` names risky pastes (tests: `PasteRiskTests`) |

## 4. The Mac

| Source | What it says | Sunset |
|---|---|---|
| Apple, entitlements reference (above) | Hardened runtime blocks loader variables and unsigned libraries unless an exception is granted | Sunset: hardened runtime, no exception; camera, microphone, location entitlements; a keychain access group. Sunset WebKit: the same plus the loader-variable exception (§1) |
| This Mac, measured (diary 2026-11-21-17) | — | WebKit's caches out of backups (28 folders marked); cookie jars and sites' storage sealed while Sunset is closed. While it runs, every file is readable by any program of the same user (A3) |

## What it changes in the threat model

1. **A10 is stronger than written**: without site isolation, a compromised WebContent reads its page's cross-site frames.
   Mitigations within reach: per-site hardening (no JIT, ADR shipped as `web.hardening`), and following WebKit's site
   isolation when it becomes stable (to try in Sunset WebKit first, measured).
2. **A new asset, the engine's freshness (D10)**, for Sunset WebKit: a release older than the last WebKit advisory runs
   known code-execution bugs. A release rule: a WebKit advisory triggers a rebuild and a release; the app could say when its
   engine is older than N weeks.
3. **The loader at launch** (A3 against Sunset WebKit): check, before anything else runs, that the WebKit loaded is the
   app's own, and refuse to start otherwise; or end the restart dance by linking the bundled frameworks directly.
4. **Extensions (A9)**: their policy table is due now. Header rewriting by our WebKit (ADR-0112) is among what it must name.
5. **The terminal (A2)**: refuse C1 controls inside UTF-8 by default (a setting for the rare program that needs them);
   add vt-houdini (`ssh termtest@termtest.dgl.cx`, or its source) to the fuzz targets' corpus.
6. **Filling (A1)**: Tóth's technique confirms ADR-0094's choice of a UI outside the page; add exact-origin matching as the
   default, subdomains on the person's choice.

Not done: Firefox's and Safari's process models read (only Chromium's and WebKit's); password-manager vault designs and
audits (the credentials research of 2026-11-19 holds them); TCC bypass history; the supply chain (SLSA, reproducible builds).
