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

`Space`, `SavedSpace`, `SavedView` and `SpacesSession` in `SunsetPane`: the session file's version 3, which reads versions
1 and 2 as one Space. Tested (`SpacesSessionTests`); **the app does not use it yet**: it still reads and writes version 2,
and each window still has its own tabs. Next: the Space at run time (`SpaceModel`), the windows as views of it, and the
app on version 3, together.

