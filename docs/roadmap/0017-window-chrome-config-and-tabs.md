---
status: not-started
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

## Open questions for the owner

1. **Blur radius**: in points, 0 to what (100? no limit)? One value for the window and one for the sidebar?
2. **Glass**: `regular`, `clear`, or both as options? Should the tint be one colour with alpha per target?
3. **Settings window editing the file**: patch only the keys it owns and keep comments (more work), or rewrite the file (loses comments)?
4. **Themes**: colour schemes inline in the one file, or separate theme files (`themes/<name>.json`) the file names?
5. **Built-in tab bar**: top or bottom, and does it show a title only or also the working directory (OSC 7) and progress (OSC 9;4)?
