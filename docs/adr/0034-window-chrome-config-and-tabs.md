---
status: accepted
date: 2026-11-07
---

# 0034 — One tab model with three presentations; a JSON configuration watched without Dispatch; private blur APIs by run-time lookup

Roadmap 0017 has the requirements and the owner's answers. This ADR records the decisions that shape the code, ; each was confirmed or changed by the stage that built it (see Evidence).

## Decision

- **Sessions belong to a `TabStore`, not to windows.** Native tabs, the sidebar and the built-in tab bar are presentations of the same store; the presentation can change while the programs run.
- **Configuration is JSON** (`~/.config/sunset/config.json`, then `$XDG_CONFIG_HOME/sunset/config.json`), parsed with AemiJSON, decoded into one `Codable` value with defaults for every key; unknown keys are reported, not fatal; an invalid file leaves the previous configuration in force and the reason is shown.
- **Live reload without Dispatch**: kqueue (`EVFILT_VNODE`) on the file's directory and the file, on a `DedicatedThread`, re-armed after rename or delete (editors save atomically), debounced; changes are applied key by key from a diff, not by rebuilding the window.
- **Private APIs are allowed** (self-signed, notarised, GitHub): their names are not written in the binary as plain strings; they are resolved at run time through InternedStrings, each behind a check that the symbol exists, with a public fallback and a log line when it does not.
- **Tab mode is `none | native | internal`.** `internal` excludes the other two.
- **Transparent materials cost an alpha channel only when used.**

## Changes made by the build

- **The sidebar is not a view of the system's tabs.** `NSWindowTabGroup` gives no way to hide the system's tab bar from code (`toggleTabBar(_:)` left `isTabBarVisible` true, tried directly and through the responder chain). With the sidebar on, the tabs of a window are terminals of that one window (`TabPresentation.hostsTabsInWindow`), like the built-in bar; the sidebar and the built-in bar are two views of one `TabList`, native tabs are windows grouped by the system.
- **Two private mechanisms, both looked up by name at run time through InternedStrings with a public fallback:** the window server's background blur (`CGSSetWindowBackgroundBlurRadius`, whole-window blur of a transparent window) and Core Animation's backdrop layer with a Gaussian blur filter (the sidebar's own radius).
- **Themes** are `themes/<name>.json` beside the config; defaults < theme < file; a theme may set only what is visual.
- **The Settings window edits the file in place** (`ConfigurationPatcher`), keeping comments and order; what a theme brought is not copied into the user's file.

## Evidence

Tests: 66 in `SunsetConfig` (schema, reader, writer round trip, patcher, loader and themes, search), 12 for `TabList` and `TabPresentation`, 7 in `SunsetPrivate`, 9 for the translucent renderer and its NEON kernel. In the running app (screenshots, this machine, macOS 27.0.1): materials, glass (regular and clear, tinted), transparency with and without blur over a coloured backdrop; native tabs, sidebar, built-in bar (top and bottom); switching between none, native, sidebar and built-in bar while three programs ran (same pids alive after each). Not verified: mouse interaction with tabs (drag, click, close buttons), several displays, full screen, other macOS versions for the private names.
