# Arc's sidebar and Spaces, and what Sunset should take (owner notes n19, n20, 2026-11-08)

Owner's goal: understand Arc's sidebar and Spaces, list what Sunset needs, and make Sunset generic enough that **a terminal screen can be replaced by a WebKit page**, which the terminal can control (JavaScriptCore, MCP or other).

## 0. How this was done, and how far it can be trusted

- Per n20 the study ran on **mbp23.local** (macOS 27.2), not on this machine. Arc was installed there with `brew install --cask arc` (cask 1.172.1, build 90370; Homebrew flags it deprecated upstream and disabled from 2026-12-22, so there will be no updates). Everything below is a **read-only inspection of the installed bundle**: `Info.plist`, the resource bundles, `Arc.sdef`, and `strings` over `ArcCore`. Nothing was launched, no account was touched, nothing was changed on mbp23 except the install and `/tmp/arc-strings.txt` (the `strings` dump).
- Tags: **[bundle]** observed in the files; **[knowledge]** how Arc behaves as a product, from what I know of it, **not checked here** (Arc was never run); **[proposal]** mine.
- Not done: running Arc and looking at the UI (it needs a sign-in; I did not try), the `StorableSidebar.json` of a real profile (none exists on mbp23), symbol-level reverse engineering of `ArcCore` (610 MB; Swift names are mangled and I did not demangle them), the remote org's sources.

## 1. What the bundle shows [bundle]

- **Shape of the app.** `Arc.app` is a thin `MacOS/Arc` plus one 610 MB `ArcCore.framework`: Chromium (C++ paths such as `../../arc/utility/importer/chrome_importer_arc_parts.cc`, Chromium's `tabs` extension API schema, `kApiTabsSplitView`) with a Swift/SwiftUI/AppKit shell. Other frameworks: Sparkle, Sentry, Lottie, Firebase/Firestore, gRPC. So the sidebar is **native UI in front of a web engine**; the web engine is replaceable per tab.
- **Feature map from the 83 resource bundles** (each `ARC_*` is one Swift module, so the names are the architecture): `StorableSidebar`, `SidebarSyncCloudKit`, `SidebarPlusButton`, `SidebarBanner`, `SpaceCreation`, `SpaceStyleEditor`, `WindowThemeUI`, `CommandBar`, `ContentPanel`, `LittleBrowser`, `PictureInPicture`, `BoostsEditor`/`BoostsDialog`, `EaselUI`, `Capture`, `AskArc`, `AppTray`, `ArcMenu`, `ContextMenus`, `SiteControlCenter`, `ProfilesUI`, `Favicons`, `MediaControlsFeature`, `AdBlocking`, `Translation`, `ImportFeature`, `Preferences`.
  - The model of the sidebar (`StorableSidebar`) is a module of its own, apart from its views and from its sync (`SidebarSyncCloudKit`): **model, views and persistence are three modules.**
- **Persistence: `StorableSidebar.json`.** The importer code (strings in `ArcCore`) shows the schema's skeleton:
  - `sidebar.containers[]` with `spaces`, `items` and `topAppsContainerIDs`; `containerIDs` per space; an **item map**: id → `{ id, parentID, childrenIds, data }` where `data` is `tab { savedURL, savedTitle }`, `itemContainer` or `list`; named containers `pinned`, `unpinned`, `pinboard`, `unsyncedPinboard`, `trash`; the importer rejects an unsupported `version`.
  - Reading: the sidebar is **a tree of items in a flat id-keyed map** (parent and children by id), with a few well-known roots per Space. A folder is an item with children; a tab is a leaf; pinned versus unpinned is which root it is under. Moving something is changing `parentID`/`childrenIds`.
- **Scripting: `Arc.sdef`** (AppleScript dictionary, 9.8 kB, its README says the implementation is `AppDelegate+Applescript.swift`). Classes: `application` (windows, tabs), `window` (tabs, **spaces**, `active tab`, `active space`, `incognito`, `mode`), `space` (`id`, `title`, tabs), `tab` (`id`, `title`, `URL` read-write, `loading`, `location`). Commands: `make`, `count`, `close`, `select`, `go back`, `go forward`, `reload`, `stop`, `focus`, and **`execute`** (runs JavaScript in a tab). So Arc already exposes "a terminal-like control surface" for its pages: list, select, navigate, run script.
- **Chromium side:** `TabInSplitView`, `kColorSplitViewBackground`, `SplitViewLayout`, `SplitViewHorizontal` in the strings: split view exists in the engine layer too (note n21 asks for it).

## 2. The concepts (what Arc's sidebar is) [knowledge, unchecked here]

1. **Space** = a named, coloured, themed workspace; each Space has its own tabs and can be bound to a profile (own cookies). Swiping or a shortcut switches Space; the sidebar's content and tint change with it.
2. **Three tiers per Space:** *Favorites* (a row of icons at the top, shared by all Spaces), *Pinned* (kept, with folders; a pinned tab remembers its URL and "resets" to it), *Today* (the unpinned tabs, auto-archived after a delay).
3. **Folders** nest tabs; **split view** shows two or more tabs side by side and the sidebar groups them as one entry.
4. **Command bar** (⌘T): one field for search, open tabs, commands.
5. **Little Arc** (a small window for a link) and **Peek** (a link opened over the page); **Boosts** (per-site CSS/JS); **Easels** (a canvas); **Archive**; **Air-traffic control** (route links to a Space).
6. The sidebar can **hide** and float over the page on hover. (Sunset already has that, and now on either side.)

## 3. What Sunset already has, and the gaps

| Arc concept | Sunset today | Gap |
|---|---|---|
| Vertical tab list | `TabSidebar`, docked or floating, either side, reorder by drag | no folders, no pinned/unpinned split, no favourites row |
| Auto-hide panel | `FloatingSidebar` + reveal strip | none |
| Spaces | none | model + switch UI + per-Space theme |
| Split view | none (n21) | pane tree + drop overlay |
| Persistence | none: tabs are not restored | a sidebar document |
| Command bar | none | later |
| Tab content = web page | no: `TerminalNSView` is hard-wired in `TabsModel` | the **Pane** abstraction (§4) |
| Scripting | none yet (`remote-control.md` is a proposal) | one control surface for all panes (§5) |

## 4. Making the screen generic: a Pane [proposal]

Today `TabsModel` swaps a SwiftUI-hosted `TerminalNSView` and the model is a terminal session. To put a web page in the same slot:

- **`Pane`** (protocol, `@MainActor`): `id`, `title`, `kind`, `workingContext` (directory or URL), `progress`, `makeView() -> NSView`, `focus()`, `close()`, and `capabilities` (what it can be asked: `text`, `navigate`, `evaluate`, `screenshot`, `input`).
- **`TerminalPane`** wraps the existing session and view; **`WebPane`** wraps WebKit.
- **Layout is a tree**, not a list: `Node = pane(id) | split(axis, [Node], weights)`. A *tab* in the sidebar is a root node, so n21's split ("two tabs shown in one tab-sized container, no close button on each") is a root whose node is a `split`. The drop overlay (left/right/top/bottom) maps to "insert next to the target pane on this edge".
- **Sidebar document** (`Workspace`): `spaces[] → roots (pinned, unpinned) → items` in an id-keyed map, like Arc's. Codable, versioned, written atomically, restored at launch. This is Arc's one good idea to copy exactly, because it makes folders, pinning, Spaces and split all "just parent/children edits".
- **Module split** (ties to `aemi-audit-2026-11-08.md` §Sunset structure): `SunsetPane` (protocol, tree, workspace; no UI), `SunsetTabs`, `SunsetChrome`, `SunsetSettings`, and the executable thin. That also gets the app code under `swift test`, which it is not now (an executable target cannot be imported).

### WebKit side, with the APIs (checked in apple-docs)

- `WebPage` (SwiftUI-era, macOS 26): `@MainActor final class WebPage`, Observable, with `load(_:)` returning an async sequence of events; `WebPage.Configuration` has `websiteDataStore`. Older and more complete: `WKWebView` (macOS 10.10+).
- **Profiles per Space:** `WKWebsiteDataStore(forIdentifier: UUID)` (macOS 14): "Use this method to get a data store for a profile"; created on first use. One UUID per Space gives Arc's per-Space cookies.
- **Running script in a page:** `WKWebView.evaluateJavaScript(_:in:in:completionHandler:)` and `callAsyncJavaScript(_:arguments:in:in:completionHandler:)` (macOS 11): the second takes arguments and awaits a Promise. `WKContentWorld` isolates our scripts from the page's.
- **Page → app messages:** `WKScriptMessageHandlerWithReply` with `WKUserContentController.addScriptMessageHandler(_:contentWorld:name:)`: a script in the page can call into Swift and get an answer.
- **Extensions:** `WKWebExtensionController` (macOS 15.4) can load WebExtensions: a way to get ad blocking and Boosts-like behaviour without our own injector. Not studied further.
- **JavaScriptCore:** `JSContext` is "a JavaScript execution environment" (macOS 10.9). It has **no DOM**; it is for running our own scripts (automation, a config/plugin language), not for driving a page. To drive a *page*, the engine is the page's own (`evaluateJavaScript`). Both can share one bridge.

## 5. How the terminal controls a page [proposal]

Three layers, same verbs as Arc's sdef, so that one client works for any pane:

1. **In-process verbs** on `Pane`: `navigate(url)`, `evaluate(js) -> JSON`, `text() -> String`, `screenshot() -> PNG`, `send(keys)`. For a terminal pane they mean write to the pty, read the screen, snapshot the CPU renderer.
2. **Scripting:** a JavaScriptCore context (our own, sandboxed, no DOM) that exposes `panes`, `spaces`, `tabs` objects over those verbs, for user automation and plugins. Each call is `await`able; the context lives on its own actor so a slow script never blocks the main thread.
3. **Out of process:** the control socket proposed in `remote-control.md`, with the same verbs as **MCP tools** (`list_panes`, `read_pane`, `send_keys`, `navigate`, `evaluate`, `screenshot`), so an agent can drive a terminal and a page with one tool set. Arc's AppleScript is the model for what to expose; an MCP server is the modern form of it.

From a shell inside a Sunset terminal: a small `sunset` CLI over the same socket (`sunset page open URL`, `sunset page eval '…'`), like kitty's `kitten @`.

**Security [proposal, to design before building]:** a page must never reach the socket; scripts run in a separate `WKContentWorld`; `evaluate` on a page is a capability that a terminal must be granted per pane (it is arbitrary code in whatever site is loaded).

## 6. What to bring to Sunset, in order

1. **`Workspace` document + `Pane` protocol + `TerminalPane`** (no visible change; unlocks everything; restores tabs across launches). Red-first tests on the tree: insert, move, split, close, round-trip JSON.
2. **Split view** (n21): the pane tree rendered with the drop overlay; sidebar entry as a grouped item.
3. **`WebPane`** on `WKWebView` (or `WebPage`), one `WKWebsiteDataStore` per Space; address in the sidebar row; basic navigation.
4. **Pinned / unpinned roots and folders** in the sidebar (one tier first), then **favourites row**.
5. **Spaces**: switch, per-Space colour (our `appearance.tint` per Space), per-Space data store.
6. **Control surface**: verbs, then the socket + MCP, then the JavaScriptCore scripting host.
7. Later: command bar, Little-Arc-style small window, Peek, auto-archive of unpinned tabs.

Not worth copying: Boosts and Easels (product features a terminal does not need), CloudKit/Firestore sync (a file is enough first), the account and analytics stack.

## 7. Open questions for the owner

- Is the web pane a browser (address bar, history, extensions) or a viewer (a docs page, a dashboard, a preview) that the terminal drives? It decides how much of §6.3–6.5 is needed. I assumed a viewer first.
- Should a Space own its panes (Arc) or only theme them (simpler)?
- Is a split's tree persisted (restored at launch) from the first version?
