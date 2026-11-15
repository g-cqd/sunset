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

## The topics proposed (the review of 2026-11-15)

Step 3 asked for a list of topics. A review by another session made one, from an inventory of the 108 options and the 120
keys: `docs/research/review-performance-memory-settings-2026-11-15.md`, section 5. It names sixteen confusions of today's
panes (a theme and its colours in two panes, the window's look in three, Layout a flat list of 31 numbers, 8 keys with no
control, 8 options named differently in the file and in Settings) and proposes six sections and 24 topics: General,
Appearance, Window, Tabs and sidebar, Terminal, Web; Layout goes, its numbers to the thing they measure. It is a proposal
until the owner approves it, with five things for him to decide (its 5.4). The code it asks for first, one declaration per
option, is task t268.

### The owner on the proposal (2026-11-15)

| Asked | Answer |
| --- | --- |
| The six sections and 24 topics | **"Yes, with changes"**, with no note: read as the changes his other answers make (the two rows below). To be confirmed when the list is shown as built |
| The cursor's colour: with the theme's colours or with the cursor | In his words: "we might want a color for the cursor as well". Read as: **the Cursor topic has its colour** beside its shape and blinking |
| `terminal.clipboardWrite` | **A Privacy and security section**, shared with the web's privacy topic |
| The 17 tab metrics | **Two topics, as proposed** |
| Names | **Settings identifiers equal the file's keys.** The `tabs.bar.*` keys are not renamed |
| What is built next | **The settings declaration** (t268): one declaration per option, then the 8 missing controls, then the regrouping |

## Built ahead of the move (2026-11-15, t268)

In the Settings window of today, so that the move into the main window has one list to draw from:

- One declaration per option: `SunsetConfig/SettingsOption*.swift` (the file's key, title, words, pane, control, note). The
  search entries, the panes' lists and the controls come from it; `SettingsRow` draws a control by its kind, and nothing is
  looked up by name.
- Controls for the 8 keys that had none.
- Identifiers equal to the file's keys.

Seen in the app by pictures only: the Font pane and four searches; no control was changed by hand.

## The sections and topics as built (2026-11-15)

In the Settings window of today: its sidebar lists seven sections and, under the one shown, its topics; a topic is a page; a
search result is under "Section › Topic". `SunsetConfig/SettingsSection+All.swift` is the list; an option is declared in the
list of its topic (`SettingsOption+*.swift`); a number of the layout is named beside the thing it measures, and the Layout
pane is gone.

| Section | Topics |
| --- | --- |
| General | Startup, closing and quitting; Configuration file |
| Appearance | Theme and colours; Accent and tint; Materials |
| Window | Title bar and buttons; Spacing and corners |
| Tabs and sidebar | Placement; Floating sidebar; Tab labels; Tab metrics; Library and documents |
| Terminal | Text; Cursor; Scrolling and history; Shell and programs; Advanced |
| Web | Address and bars; Search; Pages; Downloads; Websites; Advanced |
| Privacy and security | Programs in a terminal; Browsing |

What differs from the review's table, and why:

- **The cursor's colour is in Terminal › Cursor** (the owner's "we might want a color for the cursor as well", as read), not
  with the theme's colours.
- **Privacy and security is a seventh section** (the owner): "Programs may copy" from Terminal, and the review's Web ›
  Privacy topic, as Browsing. Web has six topics, not seven.
- Two options were renamed, because they sit side by side now (the review's confusion 4): `window.padding` is "Padding inside
  the terminal", `sidebar.padding` is "Margin around the terminal's card", each with a sentence. The keys are unchanged.

Seen in the app, in the background: every one of the 25 pages, by a picture of each
(`docs/research/settings/settings-topics-1.png`, `-2.png`; the window, `settings-sections-window.png`), the sidebar's rows
read and chosen through accessibility; searches for "cursor" and "padding". **Not seen**: a control changed by hand; the
window in the light scheme; the sidebar's rows clicked with a pointer.

To confirm with the owner: that this is what his "Yes, with changes" meant.

## Still to settle

- The topics of each section (a list to propose).
- What the settings tab is when the window is private, restored at the next start, or kept as a Favorite.

## Not done

Everything.
