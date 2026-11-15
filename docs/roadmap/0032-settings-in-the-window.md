---
status: not-started
blocked-by: 0031 (the Library's rail)
date: 2026-11-15
---

# 0032 — Settings in the window

Asked by the owner on 2026-11-15, after the Library of roadmap 0031 was decided. Task t264. Nothing is built.

## What he asked

In his words: "it would be interesting to put settings in the window as well and use the sidebar for sections and topics
and the pane area for settings themselves and asking for opening settings would use the same window or open a standard
window with settings".

## What there is today

A window of its own, the system's Settings scene (`SunsetApp.swift`), holding `SettingsView`: a list of twelve panes with a
search field, and beside it a form of the pane's options (`SettingsPane*.swift`, `SettingsView*.swift`; 117 keys). A pane
has options in one flat list; it has no topics. The search finds options in every pane and shows them with their controls.

## Sketches (2026-11-15)

Drawn by `DesignCatalogTests+SettingsInWindow.swift` (`SUNSET_CATALOG=<folder> swift test --filter "the settings in the
window, drawn"`), with plain shapes: `docs/research/settings/settings-in-window.png`.

- W1: a gear at the foot of the Library's rail (0031); the sidebar lists the sections, with the topics of the one shown
  under it; the settings are a tab like any other, so they can be beside a terminal.
- W2: the settings take the whole window; a chevron at the top of the sidebar goes back to the tabs.
- W3: the settings are a tab that carries its own list; the sidebar stays the tabs'. Drawn as the contrast: it is not what
  he asked (the sidebar is not used).

## The owner's answers (2026-11-15, on the sketch)

| Asked | Answer |
| --- | --- |
| Which | **W1**: a gear on the Library's rail; the sidebar lists the sections and topics; the settings are a tab like any other |
| What a topic is | **A page of its own**: the pane area shows one topic at a time; a section without topics is one page |
| What Cmd-, does | **The window in front, else a new one**: with no window open, a standard Sunset window opens showing them |
| The Settings window of today | **Goes** |
| How many settings tabs | **One per window** |
| When | **After the sections** (0031 with ST-5 of 0030) |

## What is to be built

1. A settings pane content: one section or topic at a time, with the controls of today (`SettingsView`'s `control(for:)`),
   shown in a tab; at most one such tab in a window.
2. A Settings glyph at the foot of the Library's rail; with it shown, the sidebar has a search field, the sections, and the
   topics of the section shown under it. Choosing one shows it in the window's settings tab, opening the tab if there is none.
3. Topics: the sections of today are flat, so each gets its topics (to be proposed to the owner as a list before it is built).
4. Cmd-, and Sunset > Settings: the window in front shows the settings; with no window, a standard one opens on them.
5. The search: its results in the settings tab, under the names of their section and topic, as today.
6. The system's Settings scene is removed once every option is reachable in the tab.

## Still to settle

- The topics of each section (a list to propose).
- What the settings tab is when the window is private, restored at the next start, or kept as a Favorite.

## Not done

Everything.
