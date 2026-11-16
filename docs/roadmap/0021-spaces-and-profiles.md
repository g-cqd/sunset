---
status: in-progress (S-a, S-b, S-c done 2026-11-17; S-d the picture, S-e, S-f and profiles not started)
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

