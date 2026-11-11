# Review of Search (driceroland/Search, by Office Commun) for Sunset's web pane

For n42 / t114. Read at e60aaab (2026-11-10), MIT, a shallow clone: the README, changelog, roadmap, the header of each relevant file and the parts of
`Tab.swift`, `Shield.swift`, `Spaces.swift` cited below. About 83,000 lines of Swift in `Sources/Search` (one executable target, Swift 5 mode, no
dependency), 20,000 of tests. Not built or run here. The repository named `theofficecommun/search` does not exist; this is the one whose description
says "by Office Commun".

## What it is, for our purpose

A WebKit browser on the **system** engine (`WKWebView`). There is no second or remote web engine in it: `Engine/` and `engine.sh` build a llama.cpp
helper for its AI add-on. So it is evidence for "system WebKit is enough", and offers nothing for "a remote or latest engine".

## Worth taking (ideas and measured facts, with where they are)

| What | Where | Note for Sunset |
| --- | --- | --- |
| One shared `WKProcessPool` for every view | `Tab.swift` `Web.pool` | Deprecated and documented as inert, yet measured there: 41-59 ms to 9-10 ms from Return to load start. Re-measure on macOS 26 before copying. |
| Safari's user agent name | `Web.userAgentName` | Without it Google serves a decade-old page. |
| Off-by-default switches a page expects | `Web.configuration` | Element full screen, AirPlay, media needing a click, inspectable. |
| A named `WKContentWorld` for the app's own scripts | `Web.world` | Pages cannot see or break them. |
| A data store per Space, removed with it | `Spaces.swift:182,248` | `WKWebsiteDataStore(forIdentifier:)`, as our Arc study proposed; the first Space keeps the default store so nobody is signed out. |
| Sleeping tabs | `Sleep.swift`, `Tab.sleep` | Drop the view after 30 min, keep `interactionState` and a snapshot; rules for what never sleeps (audio, call, upload, typed text). Maps onto our hidden-tab preview. |
| Content blocking in the network layer | `Shield.swift` | One `WKContentRuleList` compiled at launch, per-site pause. No JavaScript blocker. |
| Hide an element for good | `Hidden.swift` | Per-site selectors applied before first paint. |
| Chrome extensions on `WKWebExtension` | `Extensions*.swift`, `Crx.swift` | macOS 15.4+. The controller must be on the configuration **before** the view is made. One controller for the app, not per profile. |
| What the extension engine costs | `ExtensionShims.swift` (5,600 lines), `Trim.swift` | Chrome APIs WebKit lacks are shimmed by hand; an ad-block extension's rules compile to 150 MB and push the footprint over 1 GB for a minute. |
| Proxy on both halves | `Proxy.swift` | Each data store and each `URLSession`, or the proxy leaks. |
| A test run never touches the user's data | `Store.swift` | We want the same for sessions. |
| Driven by an agent over a socket + MCP | `Bench.swift`, `bench-mcp` | Same shape as our remote-control task t40. |

## Not to take

- **The code itself.** One 8,500-line `Browser.swift`, Swift 5 mode, main-thread everything: against every structure rule here. Ideas carry; files do not.
- **Private API.** About 80 uses of `NSSelectorFromString`/`responds(to:)` (developer extras, feature flags, frame rate, notifications, GPC). Each is a
  decision for us, not a default; none is needed for a first web pane.
- **Chrome extension shims** as an early goal: it is the largest single part of that browser and a standing source of its bug reports.
- Passwords, passkeys, importers, translation, AI, updater: a browser's business, not a terminal's pane.

## What it means for the plan

A web pane in Sunset is small if it stays a pane: one view, the Space's store, the handful of configuration lines above, title/icon/progress to the
sidebar, sleep when hidden. Content blocking is one compiled rule list. Extensions are a separate, large, optional step and should be a setting that is
off, decided after the pane exists.
