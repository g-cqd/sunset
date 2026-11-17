---
status: in-progress (S-a, S-b, S-c, P-b and P-a built 2026-11-17, P-a not seen on screen; S-d with the previews, S-e, S-f not started)
blocked-by: 0018 (each step's own questions); 0020 (Favorites and folders); 0019 (the web pane, for profiles and sleeping)
date: 2026-11-11
---

# 0021 — Spaces and profiles

Decided with the owner in refinement session R4 (`docs/refinement/R4-spaces-and-profiles.md`, accepted 2026-11-11), which is the description to
build from. Nothing is built. The owner's order: folders (0020), web (0019), Spaces, profiles. Each step starts with its own questions.

| Step | What | Task |
| --- | --- | --- |
| S-a | The model in `SunsetPane`: Spaces, their sections, the session file; a session saved before becomes one Space | t110 |
| S-b | Switching: the icons row, the swipe, keys, the command bar, the Spaces menu; the button in the tab bar; nothing with one Space | t147 |
| S-c | The Space's editor, New Space, Move to Space, drag to the edge, deleting | t148 |
| S-d | The same Space in several windows: one live view, the last picture elsewhere | t149 |
| S-e | Activity marks and notifications naming the Space | t150 |
| S-f | Sleeping and unloading pages: three settings, the exceptions, keep awake, the cue (after the study t134) | t151 |
| P-a | Profiles: a web data store each; Settings, the Space's editor, the Spaces menu; changing and deleting | t152 |
| P-b | Pinned: the profile's grid of icons | t153 |

Deferred by the owner to a much later phase: a directory, a shell environment and terminal settings per Space or profile; an editor for a
Space's look (the format leaves room). Left to study if asked: WebKit's native favourites; importing other browsers' favourites.

## The owner's answers at S-a (2026-11-16; ADR-0045, design 0004)

| Question | Answer |
| --- | --- |
| One Space, two windows | The same tabs; a click on a tab that another window shows takes its control and live rendering |
| The order of the Spaces | One for the app |
| The last window of a Space closes | Its tabs stay, stopped; a setting to clean them after a delay or at once (to design) |
| New Window | Nothing selected: the command bar open on a new tab |
| Bringing a window to the front | Takes nothing: only a click does |

The order of building changes with them: **the sharing of a Space's tabs between windows comes before switching** (it was
S-d, fourth). S-d keeps what the picture looks like.

## S-a as built (2026-11-16)

- **The file**: `Space`, `SavedSpace`, `SavedView` and `SpacesSession` (`SunsetPane`): version 3 of the session, which
  reads versions 1 and 2 as one Space. The app reads and writes it.
- **The Space at run time** (`SpaceModel`, `SunsetShell`): the tabs, the content of their panes, the Favorites. A window
  (`TabsModel`) is a view of one, with its own selection.
- **Every window that lists tabs shows the app's one Space**: the same tabs in each. A tab is drawn and typed into in one
  window, the one that last clicked it (or went to it with a key); another window that has it selected shows its last
  picture, dimmed, with "Shown in another window. Click to bring it here."
- **Closing a window closes nothing** while another shows the Space. **The last window stops the tabs and keeps them**:
  the next window, or the next launch, has them again, each started from what it was (a shell in its folder, a page at
  its address, a file).
- **New Window** shows the same tabs, none selected, with the command bar open: what is chosen or opened there is shown
  in that window.
- **One tab a window** (`tabs.mode` none, the system's tab bar): as before; a window is one tab, closing it closes the
  tab. Changing the mode while Sunset runs moves the tabs between the two.
- **A private window** has its own tabs, never saved.

Seen in a test copy: the list in the diary (2026-11-16-02).

Not done, and where it goes:

- **Only one Space exists.** Nothing makes, names, switches or deletes one (S-b, S-c). A second Space in the file is kept
  as it was read and written back, not shown.
- **The setting the owner asked for** is built (ADR-0046, the same day): `tabs.closeWithLastWindow` (the tabs close with
  the last window, as before) and `tabs.closeStoppedAfter` (hours; the tabs that stayed are closed after that long with
  no window, across a quit too). Both off by default, in Settings > General. Seen in a test copy: tabs gone at the next
  start with the first; with the second at 10.8 s, back when started at once and gone when started 14 s later.
- **No cue in the list** for a tab another window draws, or for a tab that is stopped (R4: a dimmed icon). A document
  shown elsewhere has no picture, only the label (S-d: what the picture looks like).
- **A window in front takes nothing**, as answered; the keys that go to a tab (Cmd-1..9, next, previous) do take it.
- **The font zoom is the window's**: a terminal taken by another window takes that window's size.
- Not seen: a click on a row or on the picture (keys were used); the last window closing while Sunset stays running.
- A second saved window came up 229 by 32 until the next window waits for the first to be in place: fixed by waiting a
  turn, not explained (diary).

## S-b and S-c as built (2026-11-17; ADR-0047)

The owner's answers are in the ADR. Built together: switching needs a second Space to switch to.

- **The Spaces menu**: New Space, Edit Space…, Delete Space…, Show Next/Previous Space (Option-Command-Right/Left), and
  the Spaces by name (Option-Command-1…9).
- **A row of icons at the bottom of the sidebar**, between the Library and the +, once there are two Spaces: a click
  shows the Space; its menu edits it, moves it left or right in the order, deletes it. With the built-in tab bar and no
  sidebar, one button in the bar names the Space shown and lists them.
- **The command bar** finds a Space by its name and the tabs of the other Spaces (marked with the Space's name).
- **The swipe**: two fingers sideways on the sidebar's list; the list follows, slow at first, and snaps to the next Space
  at 30% of the sidebar's width, once a gesture, with a tap of the trackpad.
- **A Space left by switching keeps running.** Every Space stops when the last window of the app closes.
- **A new Space** is named "Space N" with a numbered circle, has a copy of the Favorites of the Space it was made from
  and no tab; its editor (name, icon) opens. The first Space becomes Home, with a house, at that moment.
- **Move to Space**, in a tab's menu: the tab goes there running and the window follows.
- **Deleting** asks when the Space holds something: move it to the neighbour, or close everything.
- **The session** keeps the Spaces in their order and, for each window, the Space it showed.

Seen in a test copy (diary 2026-11-17-01): New Space and its editor; the row; Option-Command-1, 2, Right; a command still
running in a Space no window showed; the bar's row for a tab of another Space, and Return on it; both Spaces back after
a quit, the window on the one it showed; New Window on the Space in front; the question on deleting, and Move; the
button in the built-in tab bar. Pictures: `docs/research/sidebar/spaces-*.png`.

Not done, and where it goes:

- **Not seen, and not testable in the background**: the swipe and its tap (the numbers are tested, `SpaceSwipeTests`; the
  view that reads the trackpad is not), Move to Space from a tab's menu, the icons' menu (Edit, Move Left/Right), a
  click on an icon (keys and the menu were used).
- **Dragging**: a tab onto a Space's icon or to the sidebar's edge (R4), and Spaces reordered by dragging.
- **Closing the last tab of a Space closes the window**, as with one Space: to ask.
- **A new Space shows an empty window** once its editor is closed (it has no tab); the command bar does not open by itself.
- **No keys section**: the keys are fixed. No haptics layer: one call at the snap.
- **Spaces need a list of tabs**: with one tab a window only the first Space shows.
- S-d (what the picture of a tab drawn elsewhere looks like), S-e (the tabs of a Space no window shows: sleep and unload),
  S-f, profiles and the Pinned grid.

## After the owner tried S-b and S-c (2026-11-17; ADR-0048, ADR-0049)

- **The editor is a sheet** with three fields: Name, Colour, Icon; Cancel and Save. Nothing is made or changed before
  Save. The colour and the icon are fields that open their pickers.
- **A Space has a colour that tints the window** while it shows the Space (a third of it in the window's tint).
- **The last tab of a Space closing leaves the window open**, empty; `tabs.closeWindowWithLastTab` closes it.
- **The icon picker** (tabs, entries, folders, Spaces) is fast and has emoji: ADR-0048 has the measurements.

Seen in a test copy: the sheet; the picker from the Icon field, "rocket" typed and picked; a colour picked; Save making
the Space with its icon in the row; the window blue-tinted in that Space (pixel 11, 32, 49) and not in Home (10, 10,
10); Cmd-W on its last tab leaving "No tab". Pictures: `space-editor-sheet.png`, `icon-picker-from-field.png`,
`space-tinted-window.png` in `docs/research/sidebar/`.

Not done, or not seen:

- The tint does not show with an opaque window material. The Spaces row does not use the colour.
- Not seen: scrolling the picker by hand, the pointer over a cell, the colour well (any colour), the picker on a tab's
  row (it is the same view; opened only from the Space's sheet here), editing a Space that exists from the icons' menu.
- What 0047 listed and is still so: the swipe, Move to Space and the icons' menu were never seen; dragging is not built.

## The order, as the owner changed it (2026-11-17)

The Pinned grid, then acting as Chrome on some sites (roadmap 0022, W-a), then profiles, then the toggles that remove a
scope (roadmap 0033). S-d (the picture of a tab drawn in another window) is done with the tab previews, after profiles.

## P-b as built: the Pinned grid (2026-11-17; ADR-0050)

- **A grid of icon tiles at the top of the sidebar**, above the Favorites, the same in every Space: twelve at most, four
  columns that share the width, fewer as the sidebar narrows.
- **Pin**, in a tab's menu, moves the tab into the grid, still running; the menu bar's "Pin or Unpin Tab" acts on what
  the window shows. A tab's row dragged over the grid is given a slot and is pinned when dropped.
- **A tile**: a click shows the entry, opening it when it is not open; a line inside the tile says it is loaded, and
  there is none when it is not (the owner, the same day; it replaced a bar under the icon). Its menu
  resets it to where it was pinned, unloads it, renames it, changes its icon, unpins it, deletes it.
- Kept in the session, beside the Spaces.

Seen in a test copy: a document and a terminal pinned from the menu bar (two tiles, 51 by 36 and 50 by 36, the Tabs
list without them); a tile pressed showing its entry; both back, open, after a quit; the shown one unpinned and a tab
again (`docs/research/sidebar/pinned-grid.png`).

Not done, or not seen:

- **Not seen** (none can be made in the background): a drag onto the grid and its slot, the animation of a tab moving
  in, the tile's menu (Reset, Unload, Rename, Change Icon, Delete), the grid at two columns and at one.
- A favourite cannot be pinned directly; tiles are not reordered by dragging; the slot is at the end, not under the
  pointer; no grid with the built-in tab bar. ADR-0050 has the list.

## The owner's notes of 2026-11-17 on Spaces (n79, n80, n81)

- **n81, done**: the Spaces' icons are buttons of the sidebar, of the size and with the hover of the + and the Library,
  and the row is centred between the two ends (measured: its middle at 1805.5, the middle of the gap at 1805.5;
  `docs/research/sidebar/spaces-row-centred.png`). Not seen: the hover itself.
- **n79, done**: going to another Space (the swipe, the keys, an icon), the sidebar's list slides and the list of the
  other Space is drawn beside it; the window is still on the Space it leaves until the slide has ended (`SpaceSlide`).
  Under the fingers the neighbour's list is there from the first point moved. Seen: one frame at the end of a slide by
  the keys, the other Space's rows in place while the pane and the Spaces' row were still the old Space's
  (`docs/research/sidebar/space-slide-end.png`). **Not seen**: a frame in the middle of the slide (too short to catch),
  and the swipe itself.
- **n80, for profiles**: what is open in a profile shows as active in every Space of that profile, pinned and
  favourites; a question for P-a, since a new Space has a copy of the Favorites today (t152).

## P-a as built: profiles (2026-11-17; ADR-0053)

Built while the owner was away, on R4's decisions and the builder's for the rest; his to change.

- **A profile is a web identity**: its pages have their own cookies, logins and storage, and it has its own Pinned grid,
  the same in each of its Spaces. The first profile, "Personal", always exists and has what there was before.
- **Settings > Web > Profiles**: the profiles, each named in place; New Profile; Remove…, which asks, moves the
  profile's Spaces to the first, closes what was pinned in it and erases its website data.
- **A Space's editor has a Profile row** once there are two profiles; changing it loads the Space's pages again with
  the other profile's data.
- Kept with the session.

**Nothing of it was seen on screen** (the screen was locked): tested only. 1,330 tests in 255 suites pass.

Not done: history, site permissions, how sites see Sunset and zoom per profile (all shared for now); the favourites
part of n80 (his choice between two designs, ADR-0053); a profile's icon; naming the profile in the sidebar; the Spaces
menu; measuring what a profile costs.

