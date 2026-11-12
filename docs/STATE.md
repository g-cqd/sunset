# Sunset — state of the implementation (handoff)

Rewritten 2026-11-11 from the code, the tests and the log, in refinement session R10. Facts only; decisions are in the ADRs and in `docs/refinement/`.
A new session reads this, the white paper, `AGENTS.md`, `docs/roadmap/0018-refinement-phase.md`, the open tasks and the notes.

## How work is decided

White paper §10: nothing is built that was not asked for; an idea is a proposition that goes through the owner. The refinement phase (roadmap 0018)
is in progress: each topic is decided with the owner, alternatives and their costs (speed, memory, safety, security) stated, before any of it is
built. The ten sessions were held and accepted on 2026-11-11; each has a file in `docs/refinement/` and a roadmap: the web pane (0019), folders
and Favorites (0020), Spaces and profiles (0021), web beyond the first pane (0022), Markdown and the document behind a pane (0023), restoring the
running state (0024), the window shell as a library (0025), the terminal's open ends (0026). The owner's order of building: folders, the web
milestone, Markdown, Spaces, profiles, web beyond, restoring, then the terminal items and performance. R11, asked for during R6 (commands, keys, the command bar, App
Intents, remote control), was held too: roadmap 0027, built after the pane work. One session is still to hold: Sunset's own document store (t172). Nothing of all this is built.

## What exists (macOS 26, Swift 6, 172 commits, nothing pushed: there is no remote)

| Target | Size | What it is |
| --- | --- | --- |
| `SunsetCore` | 85 files, 4,750 lines | Platform-free: the parser (byte state machine, UTF-8, whole-CSI and control fast paths), the screen (8-byte cells, row map, styles, modes, regions, alternate screen, grapheme clusters, charsets), scrollback in chunks with packing, reflow on resize, replies, selection, key and mouse encoding (legacy and kitty keyboard flags), OSC (see below) |
| `SunsetHost` | 24 files | The PTY seam: spawn, the output pump on its own thread, `TerminalSession`, `HeadlessSession`, foreground command, shell integration for zsh, history packing, notification gate, host policy |
| `SunsetRender`, `SunsetRenderMac`, `SunsetRenderMetal` | 50 files | The CPU renderer (dirty rows, box drawing, ligatures and OpenType features by run shaping), CoreText glyphs, the Metal renderer; chosen at run time (`renderer`: auto, gpu, cpu), falling back to the CPU one when the GPU one fails |
| `SunsetPane` | 41 files | No dependency: `Workspace` (a window's tabs, each a split tree), split geometry, drop zones, close confirmation, saved sessions with a descriptor per pane, a tab's own name and icon; `Favorites` (folders step a1, 2026-11-11: the app-wide tree of folders and kept entries, in the model and the session file; step a2: the app reads it at launch and writes it back, whatever the restoring setting says, and **nothing in a window shows or edits it yet**) |
| `SunsetShell`, `SunsetShellBridge` | 26 + 2 files | The window shell (R8, step H-1, 2026-11-11): the tab model of a window (`TabsModel`), the pane content protocol, the sidebar and its rows, tab labels and glyphs, the command bar's state, its own plain settings (`ShellSettings`, the configuration's names); the bridge fills them from the configuration. Package access |
| `SunsetTerminal` | 30 files | The terminal as a kind of pane content (R8): its model, its AppKit view, input, selection, the renderer's wiring; what it needs from the app (the clipboard policy, the font zoom) comes in as callbacks |
| `SunsetConfig` | 22 files | The JSON configuration file, read and written, watched and applied live; 87 keys |
| `SunsetPrivate` | 3 files | Private API by run-time lookup (window blur, backdrop blur, the window's corner radius) |
| `SunsetApp` | 50 files | The app: SwiftUI scenes, settings and menus over AppKit views; no Dispatch |
| `sunset-run`, `sunset-render` | | A program's screen as text; as a PNG, with no window |

Tests: 894 in 156 suites, all passing on 2026-11-11 (`swift test`). Gates at every commit: swift-format, SwiftLint (no `try!`, `as!`, force
unwrap), one top-level type per file and 250 lines a file (a test). Benchmarks: ordo-one in `Benchmarks/`, and `bench/instructions/run.sh`
(instructions per MiB by stream, independent of the machine's load).

### The app, as built

- Windows with no title bar, movable window buttons, a drag strip; materials, blur, tint, colour scheme; themes.
- Tabs in three presentations (system tabs, a sidebar, a built-in bar), changed live; splits by menu, drag and drop; a command bar (Cmd-L) searching
  tabs; hover previews of a tab's last frame; a two-step confirmation before closing a pane, a tab or the other tabs while a command runs.
- Sessions: tabs, splits, each pane's directory, a tab's name and icon come back at launch.
- Favorites (2026-11-11): one set for the app at the top of the sidebar, above a thin line. Add to Favorites (a tab's menu); a click
  opens and shows an entry; a minus unloads it, Cmd-W unloads it with its last pane; an entry that is not open is drawn fainter with an x that
  deletes it; Remove from Favorites, Set Home to Current; Cmd-1..9 and Next/Previous count open entries, then tabs; an entry shown in a second
  window is live there and the first shows its last picture, dimmed, with a label (a click brings it back); the window stays, with a hint, when
  its last tab closes while there are Favorites; a tab dragged onto the line or onto an entry is kept there, an entry dragged among the tabs
  leaves the Favorites, entries reorder by drag; open entries lead the built-in tab bar, each with a star; the app keeps running when its last
  window closes while an entry is open (`tabs.keepRunningForFavorites`, on by default). A kept terminal can hold a command (Edit Command…), typed into its new shell
  when it opens and at relaunch; it is sealed with a key in the Keychain, and a command something else wrote into the session file is shown,
  never run, until saved in the dialog. Folders: New Folder (the sidebar's empty area, a folder's menu), New Folder with This Tab, a tab
  or an entry dropped on a folder goes in, Ungroup, Delete Folder and Its Contents (asks first when something runs); a folder never opens or
  closes what it holds (owner). Names are edited in place (Rename in a row's menu, a double-click, Shift-Cmd-R with the sidebar
  docked); Change Icon… opens a popover: the system's SF Symbols (read from CoreGlyphs, searchable, by category), the Character Viewer for an
  emoji, preset colours and a colour well for a symbol. Several rows are selected together (Cmd-click, Shift-click, across Favorites and Tabs; Escape or a plain
  click clears): New Folder with the selection, Add to / Remove from Favorites, Delete, and a drag carries the selection. In the built-in
  bar, top-level folders are chips followed by their open entries; a click collapses one (with a count), shared with the sidebar. Not yet: entries under system tabs, folders made from the UI.
- A tab can be renamed and given an emoji or an SF Symbol (Rename Tab…).
- Selection by cells, words and lines, block selection, copy and paste; links (OSC 8) opened on Cmd-click under a policy; the input method; kitty
  keyboard; mouse reporting; scrollback with trackpad and wheel inertia; Previous and Next Prompt.
- The click that activates the window gives the pane under it the keyboard.
- Panes hold `PaneContent`: a terminal (`SunsetTerminal`) or a web page (`SunsetWeb`, web step a, 2026-11-11). A note kind exists and is hidden;
  a kind a build cannot make is shown as a placeholder and kept.
- Web pages: the system's WebKit with Safari's name and version; made when first shown; the default persistent store; address, title and history
  saved and restored. Cmd-T makes a tab of the focused kind, Shift-Cmd-T asks which kind, Panes > New Web Page. Cmd-click on a link in a terminal
  opens it split beside it (`web.openLinksInSunset`). A page's link menu: Open Link in Split Right / Split Down / New Tab (after it, not shown) /
  New Window, Copy Link; Cmd-click in a page opens a tab after it. A failed load is our page (reason, address, Try Again; Visit Anyway after a
  warning for an untrusted certificate). Inspect Element by `web.developer`. A page's tab shows the first letter of its title (`web.tabIcon`).
- The address (web step b): `web.address` = a field at the top of the docked sidebar (default; the window bar stands in without a docked sidebar),
  the window bar (`web.windowBar` top or bottom: back, forward, reload/stop, the address; out when the pointer reaches its edge, gone after it
  leaves), or a row in every page. Hidden while a terminal has the keyboard. A field shows the host; a click selects the whole address; Return
  loads, Escape gives up; a thin line shows loading. History menu: Cmd-[ Cmd-] Cmd-R, Shift-Cmd-R without the cache, Cmd-. Stop. The command bar
  (Cmd-L) offers "Go to <address>" for what looks like one: the focused page, or a new page tab from a terminal. Rename Tab lost Shift-Cmd-R.
- Search (web step c, 2026-11-12): what is typed is an address (a scheme kept; this machine and the local network over http at once; a dotted host
  over https, falling back to http by `web.httpFallback`, marked Not Secure) or words searched with `web.engine` (Google, DuckDuckGo, Bing, Ecosia,
  Kagi, and `web.engines` added in the file or Settings; a keyword and a space pick one). Suggestions in the OpenSearch format (`web.suggestions`,
  on; an ephemeral session; Bing has none) in a list under the address field as wide as the content. The command bar (Cmd-L) has row states, an
  accessory per row, each row's actions on Cmd-K (Cmd-Return, Option-Return), the engine as a chip, Up recalling this session's entries.
  No find, zoom, history list, downloads, permissions or private pages: web steps d to h.

### OSC handled by the core (ADR-0010 policy)

0, 1, 2 (titles); 4, 104, 10, 11, 12, 110-112 (colours, set, queried, reset); 7 (directory); 8 (links); 9 and 9;4 (notification, progress); 22
(pointer shape); 52 (clipboard write only, behind `terminal.clipboardWrite`; read is denied); 99, 777 (notifications); 133 (prompt marks); 1337
(SetMark, CurrentDir). Not handled: 21, 66.

## Not built (found by searching the sources on 2026-11-11)

Left and right margins (DECLRMM); kitty graphics, Sixel, inline images; search in the scrollback; text sizing (OSC 66); unscroll; an own font
stack (CoreText is used); per-style fonts, fallback order and variable-font settings; Linux (no Linux code path in the sources); remote control;
session recording and replay as a feature; `esctest` / `vttest` fixtures; a crash fuzzer beyond the seeded random and differential tests; wezterm
as an oracle; bash shell integration; quitting or closing a window is not confirmed.

## Measured (2026-11-11, headless, release, instructions per MiB)

Plain ASCII 33 M · dense colour 76 M · cursor moves 78 M · full lines 30 M · titles 116 M · short lines (real scrolling) 257 M · unicode 166 M.
The app against Ghostty on vtebench was last measured before 2026-11-11 (dense equal; scrolling 26 vs 17 ms, regions 20 vs 15, fullscreen 34 vs
22, unicode 8 vs 2) and **not** since the scrolling work of that day. Performance work is deferred by the owner (task t100).

## Not verified, said plainly

Much of the app's UI was built without being exercised by hand: the hover preview, sidebar drag and drop, rapid close, the rename dialog, the
pointer shapes, Previous and Next Prompt in the running app. The CI workflows were written and never run. Each task says what was and was not tried.
