# Review, 2026-11-15: Sunset and ask — tab click delay, CPU, memory, and the Settings reorganisation

> Kept here as research on 2026-11-15: a review written by another session, read-only, given by the owner as
> `REVIEW-2026-11-15-performance-memory-settings.md` at the family's root. **Its numbers are the review's, not ours**, and its
> fixes are claims until probed. What was probed here, and what became of each section:
>
> | Section | Here |
> | --- | --- |
> | 1, the click held for a double click | Probed in the real sidebar and fixed the same day (diary 2026-11-15-01, `SidebarClickTests`; task t205) |
> | 2.1, the chrome re-applied at each title change | Not probed: task t265 |
> | 2.2 and 3.1, shaped runs and glyph bitmaps | Not probed: task t266 |
> | 3.2, surfaces of quiet and hidden terminals | Not probed: task t267 (owner note n14) |
> | 4, ask | Not Sunset's: for the ask repository |
> | 5, the settings | The list of topics that roadmap 0032 asked for: roadmap 0032 and task t264; the declaration of options is task t268 |


Read-only review. No source file was changed, nothing was built or tested in either repository. Measurements were taken on the
running processes with `sample`, `vmmap`, `heap` and `top`.

| Process | Build | Uptime | Footprint (peak) | CPU when measured |
|---|---|---|---|---|
| Sunset, pid 82965 | 23a4544 (2026-11-14; 18 commits behind HEAD 9cf02db) | 3 h 57 | 510 MB (580 MB) | 4 % steady, about 220 context switches/s |
| ask, pid 83243 (cwd `ask`, resumed session, 79 MB / 35,191 entries) | installed `~/.local/bin/ask` | 3 h 56 | 191 MB (280 MB) | 0.0 % idle |
| ask, pid 83250 (cwd `sunset`, resumed session, 39 MB / 16,107 entries) | same | 3 h 56 | 199 MB (298 MB) | 0.4–3.5 % with a live block |
| ask, pid 1695 (fresh session) | same | 57 min | 29 MB | 0 % |

Sunset had 6 terminals (6 `TerminalModel`, 2 `TerminalNSView` attached). The two large ask processes run inside it.

---

## 1. Sunset: why a tab does not switch at the click

**Cause: the sidebar rows wait for a possible double click before the single click is delivered.**

Three row kinds attach a double-tap (rename) before the single tap (select):

- `Sources/SunsetShell/TabSidebar.swift:164-165` (a tab)
- `Sources/SunsetShell/FavoritesSection.swift:62-63` (a favourite)
- `Sources/SunsetShell/FolderRow.swift:55-56` (a folder)

```swift
.onTapGesture(count: 2) { tabs.renamingRow = .tab(item.id) }
.selectionTaps(tabs, row: .tab(item.id)) { tabs.select(item: item.id) }   // View+SelectionTaps.swift: cmd tap, shift tap, then onTapGesture
```

With a count-2 tap on the same view, SwiftUI holds the single tap until the double tap has failed. The double tap came with
84e8f37 (2026-11-12, "R3 step c: names in place"), which is in the running build.

**Measured** in a standalone harness that copies the exact modifier stack and sends synthetic mouse events to an
`NSHostingView` (`/tmp/tapprobe/main.swift`, three runs):

| Gesture stack | Single-click handler runs |
|---|---|
| A: Sunset's sidebar row (double tap, cmd tap, shift tap, single tap) | 351–352 ms after mouse up |
| B: Sunset's top bar row (`BuiltInTabBar+Rows.swift:82`, single tap only) | 0–1 ms |
| C: single tap first, then `.simultaneousGesture(TapGesture(count: 2))` | 0–1 ms; a double click still runs the double handler |

`NSEvent.doubleClickInterval` is 0.5 s on this machine.

**Why t205 did not find it.** `SwitchProbe` calls `tabs.select(item:)` directly, so it measures only what happens after the
gesture. Its numbers (diary 2026-11-13: `select` 0.12 ms, 22–30 ms until the run loop is idle) are the smaller part: roughly
350 ms of wait, then about 30 ms of work. Notes n15, n56 and n59 describe the sum.

**Suggested fix.** Deliver the single tap at once and treat the double click as an addition, as in C: selecting on the first
click and renaming on the second is harmless for a tab and a favourite. For `FolderRow` a double click would toggle the folder
twice and then rename; either accept that, or move rename off the double click for folders (it is already in the context
menu). Alternative: one `onTapGesture` that reads `NSApp.currentEvent?.clickCount`.

**Not verified:** the delay was reproduced in the harness, not timed in the app itself. Variant C was not tried in the app,
where `.onDrag`, `.iconPopover`, `.contextMenu` and the scroll view's `WindowDragGesture` (`TabSidebar.swift:66`) are also on
the row. A probe that goes through the gesture (a synthetic click on a row) should replace or join `SwitchProbe`.

---

## 2. Sunset: CPU while nothing is typed

Sunset held 4 % CPU for the whole observation while one ask instance animated a running block. Two things showed in a
4-second sample.

### 2.1 Every title change re-applies the window chrome (main thread)

About half of the main thread's SwiftUI render time (24 of 47 samples) was in this chain:

`TerminalScene.swift:118` `.navigationTitle(tabs.selectedContent?.title ?? "Sunset")`
→ SwiftUI `BarAppearanceBridge.updateWindowTitle` sets the window's title visibility
→ KVO observers in `ChromeView.swift:47-54`
→ `ChromeView.apply()` (`:76`) → `backdrop.apply`, `applyTabbing`, `placeButtons()` (`:104`), which reached
`removeFromSuperview` and `_setWindow:` on the traffic-light buttons.

SwiftUI puts the title back and `ChromeView` hides it again on each change. ask sends the tab's title and progress as it
works, and the chain ran repeatedly during the sample; how often per second was not counted.

Suggested: stop feeding the changing title through `.navigationTitle` when the title bar is hidden (set `window.title` from
one place, or only when the value differs), and make `apply()` return early when nothing it sets has changed, without
calling `placeButtons()`.

### 2.2 Shaped runs miss the cache and go through CoreText on each frame

In `TerminalModel.tick` → `MetalSurfaceRenderer.draw` → `CPURenderer.render`, 13 of 16 render samples were in
`CPURenderer.shaped` → `CoreTextGlyphSource.glyph(forRun:)` (`CPURenderer+Runs.swift:85-124`). The cache key is the whole run
(up to `maxRun = 32` cells), so text that changes by one character (a counter, a clock, a spinner beside a word) is a new run
and a new CoreText rasterisation. This is also the memory problem of 3.1.

Suggested: shape by word or by ligature-capable cluster, not by style run. To check first: whether runs are shaped at all
when `font.ligatures` is off (not read).

Also seen, not investigated: 12 threads blocked in `poll` for 6 terminals.

---

## 3. Sunset: memory (510 MB, 6 terminals)

| Region | Size | What it is |
|---|---|---|
| IOSurface | 205.6 MB (78.9 MB of it swapped) | 15 terminal surfaces: 12 of about 10.5 MB, 3 of 26.2 MB |
| Malloc small | 195.8 MB (125 MB swapped) | 110 MB of it is glyph bitmaps |
| Graphics (IOAccelerator, owned unmapped) | 46 MB | |
| Malloc large, empty | 25 MB | freed, not returned |

### 3.1 Glyph bitmaps are never trimmed: 110 MB

`heap`: 25,306 `[UInt8]` arrays, 110.0 MB, average 4.3 KB, beside 25,189 `GlyphBitmap` and 15,935 `RunEntry` objects.

- `GlyphTable.number(_:)` (`SunsetRender/GlyphTable.swift:67`) appends every bitmap; the only release is `startAgain`, taken when
  a table reaches `glyphTableLimit = 16_384` (`CPURenderer.swift:17`, `CPURenderer+Glyphs.swift:10`).
- `runCache.removeAll()` at `runCacheLimit = 8192` (`CPURenderer+Runs.swift:118`) forgets the lookups but not the bitmaps, so
  the same runs are shaped and stored a second time.
- Each `CPURenderer` has its own table; nothing is shared between terminals with the same font.

At the measured average the ceiling is about 70 MB per terminal, with no limit across terminals.

Suggested: bound the table by bytes; let run bitmaps be evicted on their own (LRU) rather than living in the numbered table;
share single-cell glyphs between renderers of one font and size.

### 3.2 Surfaces are kept for idle and hidden terminals: 206 MB

- `SurfaceRing` makes a third surface under fast output and drops it only inside `next()` (`SurfaceRing.swift:41-42`), that is
  on the next frame. A terminal that goes quiet keeps all three. The 15 surfaces for 5 rings are consistent with every ring
  being at three.
- Nothing releases a ring when its terminal is not shown: `ring` is only assigned in `MetalSurfaceRenderer.swift:71-109`, and
  only 2 of 6 terminals had a view. 79 MB of these surfaces were swapped out, which fits surfaces nobody touches.

Suggested: release the third surface on a timer rather than on the next frame; release all of a hidden terminal's surfaces
after a delay and redraw on show. This is note n14 ("memory compression for screens that show no activity").

**Not verified:** whether hidden terminals still render frames; the first-frame cost after a ring is released.

---

## 4. ask: memory and CPU

### 4.1 The whole session is held decoded: 190–200 MB on long sessions

A fresh ask is 29 MB. The two resumed ones are 191 and 199 MB, with peaks of 280 and 298 MB at resume.

pid 83243 (79 MB session file):

| Class | Count | Bytes |
|---|---|---|
| `Swift.StringStorage` | 136,982 | 94.3 MB |
| `[UInt8]` | 18,122 | 21.5 MB |
| `[SessionEntry]` (one array) | 1 | 12.6 MB |
| `[Int: BlockProgress]` | 1 | 3.2 MB |
| `[Transcript.Item]` | 1 | 2.6 MB |
| Malloc large, empty | | 30 MB |

`SessionTree.entries` (`AskAgentCore/Session/SessionTree.swift:11`) keeps every entry with its full payload, tool output
included, and the transcript keeps its own items. The session file is open on two descriptors.

pid 83250 additionally holds the session search index after one search: 42,388 `AemiSearch.Posting` arrays (14.4 MB),
53.8 MB of `[UInt8]`, 18.5 MB of `Data`, 18,432 `[String: String]`. `SessionSearch.index` (`SessionSearch.swift:24`) is never
dropped.

Suggested: keep entry identifiers, parents and file offsets in memory and read payloads from the file on demand (the active
branch after the last compaction is what the model needs); drop or memory-map the search index after a quiet period; the
resume peak is the same decode that makes `/reload` slow (note n47, t233).

**Not verified:** the 160 MB that `heap` lists as "non-object" in pid 83250; how much of the string storage is the tree and
how much the transcript.

### 4.2 Each animation tick copies and frees the progress of every block ever shown

While a block is live, `BlockProgressTimer` ticks every 60 ms (shimmer) or 200 ms. In a 4-second sample of pid 83250:

- render thread: 13 of 24 samples in `RenderLoop.frame` were `destroy for ScreenState` → `_DictionaryStorage.deinit` →
  `destroy for BlockProgress`;
- main: 12 samples in `Transcript.advanceProgress` (`Transcript+Progress.swift:75-81`).

`ProgressClocks.clocks` (`ProgressClocks.swift:5`) is one `[Int: BlockProgress]` with an entry per block of the session
(3.2 MB of storage here). The render loop holds the previous `ScreenState` (`RenderLoop.swift:147-148`), so the mutation of a
live clock copies the whole dictionary, and the old copy is freed entry by entry on the render thread. The cost grows with the
session's length, not with the number of live blocks; `ProgressClocks.live` solved the lookup (note n55) but not the copy.

Suggested: keep the live clocks in a small dictionary of their own and move a clock to an immutable store when it ends (an
array or a boxed reference), so a tick copies only the live ones.

Idle is fine: pid 83243 used 0.0 % with all 17 threads blocked.

---

## 5. Sunset Settings: what is confused today, and a proposal for sections and topics

Context: roadmap 0032 (t264) is decided as W1 (a gear on the Library's rail, sections and topics in the sidebar, one topic
per page) and its step 3 asks for a list of topics to propose. Notes n12 and n57 (t206) ask for a structure modelled on System
Settings, Safari and Xcode. This section is that list, built from an inventory of the 108 options in `SettingsPane*.swift`
and the 120 keys in `ConfigurationKeys.swift`.

### 5.1 Today's panes

| Pane | Options | Pane | Options |
|---|---|---|---|
| Font | 4 | Tabs | 11 |
| Colors | 4 | Scrolling | 4 |
| Appearance | 12 | Terminal | 9 |
| Window | 5 | Web | 19 |
| Sidebar | 7 | Keyboard | 1 |
| Layout | 31 | Configuration file | 1 |

### 5.2 Confusions found

1. **A theme and its colours are in two panes.** `theme.name` is in Appearance; the foreground, background, cursor and ANSI
   colours it sets are in Colors.
2. **The window's look is spread over three panes.** `window.material`, `window.blur` and `window.padding` are in Appearance
   although their keys say window; `terminal.opacity` ("Background opacity"), which only matters together with the material
   and blur, is in Terminal; the Window pane holds only the title bar and the traffic lights.
3. **Traffic lights are in two panes.** Side and offsets in Window; `lightsInset`, `lightsGap`, `floatingLightsExtra` in Layout.
4. **The margins are in two panes under misleading names.** `window.padding` ("Padding") is in Appearance; `sidebar.padding` is
   in Sidebar but titled "Space around the terminal".
5. **Where the tabs are is decided in two panes by three options.** `sidebar.enabled` and `sidebar.side` in Sidebar; `tabs.mode`
   and `tabs.position` in Tabs.
6. **The Tabs pane mixes three subjects:** placement (mode, position), the app's life cycle (restore at launch, confirm on
   close, ask before quitting, keep running for favourites), and the look of a tab's label (icon, title, directory, monospace,
   progress). The label options apply to sidebar rows too, yet their keys are `tabs.bar.*`.
7. **Layout is one flat list of 31 numbers.** Eight tab metrics, the same eight again for the floating sidebar, traffic
   lights, sidebar buttons, hairlines, split gaps, radii, and two that are behaviour rather than layout (`hideDelay`,
   `animation`).
8. **The floating sidebar has 13 options and no switch.** `sidebar.autoHide` is only reachable through the pin button.
9. **Sidebar holds content options** (`sidebar.library`, `sidebar.documents`, `sidebar.documentSort`) beside chrome options.
10. **Scrolling holds the history length** (`scrollback.lines`), which is memory, not scrolling feel.
11. **The cursor is in two panes:** colour in Colors, shape and blinking in Terminal.
12. **Terminal is a remainder:** a look (opacity), the cursor, the renderer, the start directory, shell integration and a
    permission (`terminal.clipboardWrite`).
13. **Web is 19 options in one list** covering bars, search, zoom, history, private browsing, per-site permissions and
    developer options.
14. **Keys with no control at all (8):** `sidebar.autoHide`, `appearance.accent`, `web.downloadFolder`, `web.askWhereToSave`,
    `web.openSafeDownloads`, `web.notifyDownloads`, `web.approveRiskyDownloads`, `web.keepDownloads`.
15. **Two vocabularies for one option.** The settings identifier differs from the configuration key: `window.decorations` /
    `window.titlebar`, `window.trafficLights.x` / `window.lightsX`, `scrollback.lines` / `scroll.history`, `renderer` /
    `terminal.renderer`, `cursor.blinkTimeout` / `terminal.blinkTimeout`, `keyboard.optionAsMeta` / `keyboard.meta`,
    `tabs.bar.icon` / `tabs.icon`, `appearance.tint.color` / `appearance.tint`. Search results and the file therefore name the
    same thing differently.
16. **Code: one option is declared in up to five places** (the `Configuration` struct, `ConfigurationKeys`, the `SettingsPane`
    entry, a `case` in a `SettingsView` switch, the binding), and the control lookup is a chain of string switches whose
    `default:` falls through to the next function and ends on a real control: `SettingsView+Looks.swift:166` (the "Show
    progress" toggle), `SettingsView+Web.swift:63` (the tab icon picker), `SettingsView+Tint.swift:19` ("Tint strength"). An
    identifier with no case shows the wrong control instead of failing. ask has the same subject open as t242 (roadmap 0209,
    one declaration per setting).

### 5.3 Proposed sections and topics

Six sections, 24 topics; every one of the 108 options has one place, and the 8 keys without a control get one (marked *new*).
Layout disappears as a pane: its numbers go to the thing they measure.

| Section | Topic | Options |
|---|---|---|
| **General** | Startup, closing and quitting | `tabs.restore`, `tabs.confirmClose`, `tabs.askBeforeQuit`, `tabs.keepRunningForFavorites` |
| | Configuration file | `file.location` |
| **Appearance** | Theme and colours | `theme.name`, `appearance.scheme`, `colors.foreground`, `colors.background`, `colors.cursor`, `colors.ansi` |
| | Accent and tint | `appearance.accent` (*new*), `appearance.tint` and its three variants, `appearance.barTint` |
| | Materials | `window.material`, `window.blur`, `terminal.opacity`, `appearance.glass`, `appearance.barBlur` |
| **Window** | Title bar and buttons | `window.titlebar`, `window.dragStrip`, `window.lightsSide`, `lightsX`, `lightsY`, `layout.lightsInset`, `lightsGap`, `floatingLightsExtra` |
| | Spacing and corners | `window.padding`, `sidebar.padding`, `layout.terminalRadius`, `innerCornerRadius`, `paneGap`, `resizeHandleWidth`, `hairlineWidth`, `hairlineOpacity`, `animation` |
| **Tabs and sidebar** | Placement | `tabs.mode`, `tabs.position`, `sidebar.enabled`, `sidebar.side`, `sidebar.width`, `sidebar.autoHide` (*new*) |
| | Floating sidebar | `layout.hideDelay`, `revealStripWidth`, `panelRadius`, `sidebarButtonSize`, the 8 `floating…` tab metrics |
| | Tab labels | `tabs.bar.icon`, `title`, `directory`, `monospacedDirectory`, `progress`, `web.tabIcon` |
| | Tab metrics | the 8 docked tab metrics, `sidebarButtonRadius` |
| | Library and documents | `sidebar.library`, `sidebar.documents`, `sidebar.documentSort` |
| **Terminal** | Text | `font.family`, `size`, `ligatures`, `features` |
| | Cursor | `cursor.shape`, `cursor.blink`, blink for ever, `cursor.blinkTimeout` |
| | Scrolling and history | `scroll.trackpad`, `wheel`, `inertia`, `scrollback.lines` |
| | Shell and programs | `terminal.directory`, `terminal.shellIntegration`, `terminal.clipboardWrite`, `keyboard.optionAsMeta` |
| | Advanced | `renderer` |
| **Web** | Address and bars | `web.address`, `windowBar`, `splitBar` |
| | Search | `web.engine`, `engines`, `suggestions`, `privateSuggestions` |
| | Pages | `web.openLinksInSunset`, `httpFallback`, `zoomScope`, `textOnlyZoom` |
| | Downloads | the 6 download keys (*new*) |
| | Privacy | `web.historyKeep`, `clearHistoryOnQuit`, `clearWebsiteDataOnQuit`, `privateWindowShares` |
| | Websites | `web.permissions.*` |
| | Advanced | `web.developer`, `fullFrameRate` |

Sections that open tasks will add: Keyboard (t187, at which point `keyboard.optionAsMeta` moves there), Storage (t257), Profiles
(t152), Spaces (t151), Restore (t175, t176, under General).

### 5.4 For the owner to decide

1. **The cursor's colour:** with the theme's colours (proposed, since a theme sets it) or with the cursor's shape and blinking.
2. **`terminal.clipboardWrite`:** under Terminal (proposed) or in a Privacy and security section shared with the web's privacy
   topic, as System Settings does.
3. **The 17 tab metrics:** two topics as proposed, or one "Metrics" topic at the end of the section so that ordinary options
   are not beside numbers few people change.
4. **Identifiers:** make the settings identifier equal to the configuration key (proposed; it removes confusion 15 and lets one
   declaration drive the file, the search and the control), or keep both.
5. **The tab label keys** are `tabs.bar.*` although they apply to the sidebar: rename to `tabs.label.*` with the old names still
   read, or leave.

### 5.5 Suggested order of work

1. One declaration per option (key, title, keywords, section, topic, control kind, default); generate the search entries
   from it and replace the chained switches with a lookup that fails loudly on an unknown identifier. Without this, moving 108
   options between topics means editing four lists by hand.
2. Add the 8 missing controls.
3. Regroup into the sections and topics the owner approves; this is step 3 of roadmap 0032 and can be done in the Settings
   window of today before the settings move into the main window.

---

## 6. Priorities

| # | Change | Effect | Size |
|---|---|---|---|
| 1 | Sunset: single tap not held by the double tap (section 1) | about 350 ms off every sidebar click | small |
| 2 | ask: live clocks apart from ended ones (4.2) | removes a per-tick copy that grows with the session | small |
| 3 | Sunset: no chrome re-apply on a title change (2.1) | about half of the main thread's render samples while a program retitles the tab | small |
| 4 | Sunset: release surfaces of quiet and hidden terminals (3.2) | up to about 200 MB here | medium |
| 5 | Sunset: bound and share glyph bitmaps; shape smaller runs (3.1, 2.2) | about 110 MB here, and the CoreText cost per frame | medium |
| 6 | ask: session payloads on demand, search index dropped (4.1) | 160 MB or more on long sessions; faster resume and `/reload` | large |
| 7 | Sunset: settings declaration, missing controls, regrouping (5.5) | | large |

## 7. Limits of this review

- Nothing was changed, built or tested; every fix above is a suggestion that has not been tried.
- The click delay was reproduced in a harness with the same gesture stack, not timed inside Sunset.
- The switch cost after the click (22–30 ms) is quoted from the diary of 2026-11-13, not measured again.
- The CPU samples are 4 seconds each, taken while one ask instance had a live block; a different workload will weigh
  differently.
- The running Sunset is 18 commits behind the repository's head; the cited lines were read at head and the double-tap commit
  was checked to be in the running build. The other cited code was not compared between the two.
- The Sunset repository had 36 uncommitted paths at the time; another session is working in it.
