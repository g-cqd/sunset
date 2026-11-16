---
status: in-progress (S-a: the model and the file, 2026-11-16; nothing of it shows yet)
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
- **The setting the owner asked for**, to clean the tabs of a Space after its last window closed (at once, or after a
  delay): next, before S-b.
- **No cue in the list** for a tab another window draws, or for a tab that is stopped (R4: a dimmed icon). A document
  shown elsewhere has no picture, only the label (S-d: what the picture looks like).
- **A window in front takes nothing**, as answered; the keys that go to a tab (Cmd-1..9, next, previous) do take it.
- **The font zoom is the window's**: a terminal taken by another window takes that window's size.
- Not seen: a click on a row or on the picture (keys were used); the last window closing while Sunset stays running.
- A second saved window came up 229 by 32 until the next window waits for the first to be in place: fixed by waiting a
  turn, not explained (diary).
