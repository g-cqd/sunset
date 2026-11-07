---
status: in-progress
blocked-by: 0009 (the app shell exists), AemiJSON (read, see below)
date: 2026-11-07
---

# 0017 — Window chrome, a live configuration file, tabs, a sidebar, materials and blur

The owner's request of 2026-11-06 (kept close to their words), refined by their answers of the same day. Nothing here is built yet. Decisions are in ADR-0034 (proposed).

## Requirements

1. **No window decorations.** No title bar. The traffic lights stay, as controls that can be **moved inside the window** (position in the configuration). With no title bar, a **16 pt strip at the top** of the window drags it.
2. **A configuration file the terminal watches and applies live**: colour scheme, font, *all the parameters we rely on*, window decoration, the renderer (`auto | gpu | cpu`). **JSON**, read with **AemiJSON** (and AemiHMMML if another format is wanted later). A settings window edits the same settings.
3. **Tabs: one model, three presentations.** The tabs are one list of sessions. They are shown (a) as **native macOS tabs**, (b) in an optional **vertical sidebar** that extends the window, or (c) in the terminal itself as **built-in tabs** (a tab bar drawn by the renderer, the way kitty does it; the name in settings is `internal`, never "kitty"). Native tabs and the sidebar are two views of the *same* tabs; when built-in tabs are on, native tabs and the sidebar are off. The sidebar shows **only the tabs** for now.
4. **Sidebar layout.** The terminal lives inside the window; **2 to 4 pt of space all round the terminal while the sidebar is shown, none when it is not.**
5. **Materials.** The sidebar and the window can each be **opaque, material, glass or fully transparent**, each with a **tint**. **Blur and a blur filter from the system's APIs**, private ones allowed (the app is self-signed and notarised for GitHub, not the App Store; names looked up at run time through InternedStrings), with the radius "to whatever extent we want". Settable in the file or the settings window.

## Owner's answers (2026-11-06)

| Question | Answer |
|---|---|
| Private APIs | Yes. Self-signed, notarised, distributed on GitHub. InternedStrings (aemisdr) for run-time lookup of private names. |
| Configuration format | JSON, with AemiJSON and AemiHMMML to help. |
| Sidebar content | Just the tabs. |
| Drag area with no title bar | Maybe a 16 pt strip at the top. |
| Tab mode | Either native or the built-in kind, but not called "kitty": `none`, `native`, `internal`. |

## Stages (each red-first, each measured where it has a cost)

| # | Stage | What exists at the end |
|---|---|---|
| S1 | **Configuration**: schema (Codable over AemiJSON), defaults, validation with messages that name the key, file locations (`~/.config/sunset/config.json`, then `$XDG_CONFIG_HOME`), a watcher without Dispatch (kqueue on the directory and the file, re-armed after an atomic save, 100 ms debounce), diff old to new, apply per key (font, colours, cursor blink timeout, scrollback limit, renderer), an invalid file keeps the previous configuration and says why | change the font in the file, the window follows |
| S2 | **Chrome**: full-size content view, hidden title and bar, the real traffic-light buttons moved into our container at the configured position, the 16 pt drag strip | a window with no title bar that can be moved and closed |
| S3 | **Tab model**: `TabStore` (sessions and models live in it, not in windows), selection, order, move, close; native presentation (one `NSWindow` per tab, `tabbingIdentifier`); switching presentation at run time moves the sessions, the programs keep running | `tabs.mode: native` |
| S4 | **Sidebar and built-in tabs**: the sidebar view over the same store, the 2-4 pt padding rule; the built-in tab bar as cells drawn by the renderer | `tabs.mode: internal`, `sidebar.enabled` |
| S5 | **Materials and blur**: surface with alpha (premultiplied, an IOSurface format with alpha), window and sidebar modes (opaque, material, glass, transparent), tint, blur radius through the private window-server call, glass through the public glass view | `window.material`, `sidebar.material` |
| S6 | **Settings window** bound to the same values; edits patch the file and keep the user's comments | one place to set everything |

## Design notes (to be settled in the ADR as each stage lands)

- **Native tabs are windows.** AppKit's tabbing shows one `NSWindow` per tab. The sidebar and the built-in bar show many tabs in one window. So sessions cannot belong to windows: they belong to `TabStore`, and a window is a view that shows one session at a time. That is what lets native and sidebar be "the same tabs" and lets the mode change while programs run.
- **Traffic lights.** Keep the system's own three buttons (they keep Option-click zoom, full screen, tooltips) and reparent them into a container we place; custom-drawn lookalikes are the fallback if reparenting breaks on a macOS release.
- **Blur.** Public: `NSVisualEffectView` materials and, on macOS 26, the glass effect view with a tint. Free radius: the private window-server background-blur call (as iTerm2 and Ghostty use), looked up by name at run time; if the name is missing the setting falls back to the nearest material and says so in the log.
- **No Dispatch for the watcher.** FSEvents needs a dispatch queue, so it is out (`BannedAPITests`); kqueue on a `DedicatedThread` is not.
- **Cost.** The surface gains an alpha channel only when a transparent material is on; the default stays opaque so the measured costs do not move.

## Status (2026-11-07)

| Stage | State |
|---|---|
| S1 configuration, live reload, themes | done (35 keys, JSON5, patching keeps comments, theme files watched) |
| S2 chrome | done: no title bar, traffic lights anywhere, drag strip; drag by real mouse not yet verified |
| S3 tab model | done: `TabList` + `TabPresentation` (12 tests), `TabsModel`, `TabRegistry`; native tabs, sidebar, built-in bar, live switching with the programs kept running |
| S4 sidebar, built-in bar | done: sidebar of the window's tabs, 2-4 pt padding, materials; built-in bar top or bottom, customizable content |
| S5 materials, blur | done: opaque, material, glass (regular, clear), transparent, one tint, window blur (private call) and sidebar blur (private backdrop layer) |
| S6 settings window | done: sidebar of panes with search, every option |

One decision came out of the build: **the sidebar is not a view of the system's native tabs.** `NSWindowTabGroup` has no public way to hide the system's tab bar (`toggleTabBar(_:)` changes nothing from code while the group has several windows: tested), so with the sidebar on the tabs of a window are terminals of that one window (like the built-in bar), listed in the sidebar. `native` + sidebar is therefore "tabs in the sidebar", and `native` without it is the system's tabs. `TabPresentation.hostsTabsInWindow` says which.

## Decisions (2026-11-07)

| Question | Answer |
|---|---|
| Settings layout | Sidebar with search (System Settings style; owner note n12 shows both styles) |
| Blur radius | Separate for window and sidebar, 0 to 100 pt |
| Settings window and the file | Patch only the keys it changes, keep the user's comments and order (replaces "rewrite the whole file", which is what S6 does until then) |
| Themes | Separate files, `themes/<name>.json` next to the config; the config names one |

Added from notes: n13 stop blinking when focus is lost (done, see diary), n14 compress idle screens and restore on input or focus, per tab and per window (needs S3).

Answers of the same day to the three that were open: **glass** regular and clear, one tint shared by window and sidebar; **built-in tab bar** customizable (position, what a tab shows: title, working directory, progress), so those are settings, not fixed choices; **themes** may set everything visual (colours, material, tint, blur, font), and the config can still override any of it.

## Still open

1. Precedence between a theme and the config file's own keys (proposed: config file key beats theme, theme beats default).
2. Whether the font in a theme can be overridden by a launch option (proposed: launch option beats everything).
