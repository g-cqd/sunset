---
status: not-started
blocked-by: its own refinement (the owner's answers on the sketches)
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

## To ask

- Which of W1, W2, W3.
- What a topic is: a heading within a section's page that its row scrolls to, or a page of its own.
- What "the same window or a standard window" means: which one Cmd-, does, and whether the window of today stays.
- Where a setting's search is, and what it shows.
- When it is built: with 0031 (it uses the Library's rail), or after.

## Not done

Everything.
