# 0004 — Spaces: what holds the tabs, and what a window is

What is intended for roadmap 0021 (R4, and the owner's answers of 2026-11-16). ADR-0045 says why. Built so far: the
file, the Space at run time, and windows as views of the app's one Space; not the setting that cleans stopped tabs, not
a second Space.

## The three things

| Thing | Holds | Lives |
| --- | --- | --- |
| A **Space** | A name, an icon, a look (room only), a profile (one for all until P-a), its **Favorites**, its **Tabs** in order, and the content of every pane of both | Once for the app; in the session file |
| A **window** | The Space it shows, the tab or kept entry it has selected, and what is only its own (the command bar, a rename in progress, the pointer) | While it is open; in the session file as a view |
| The **Spaces** | The Spaces, in one order for the whole app | Once for the app |

A tab is in one Space, and a pane in one tab. A window shows one Space and lists all of its tabs: two windows on one
Space list the same tabs.

## One live view

The content of a pane is one view, so a tab is **live** in one window at most: where it is drawn and typed into. A
window that has a tab selected which is live elsewhere shows its last picture. A click on the tab, or on the picture,
takes it: the window that had it shows the picture in turn. Bringing a window to the front takes nothing (the owner).
This is what kept entries already do between windows (`FavoritesModel.claim`); tabs do the same.

## What a window does to the tabs

- **Closing a window closes nothing** while another window shows the Space.
- **Closing the last window of a Space stops its tabs and keeps them**, after the questions asked today about running
  commands and unsaved edits: a shell is ended, a page released; the tab stays in the Space, dimmed, and starts again
  from where it was when it is next shown (as at a relaunch). A setting will clean such tabs away, after a delay or at
  once (to be designed with the owner: `spaces.*`).
- **New Window** opens on the same Space with nothing selected and the command bar open on a new tab: what is chosen
  there becomes a tab of the Space, shown in that window.
- **Without a list of tabs** (`tabs.mode` none, or the system's tab bar): a window is one tab of the Space, and closing
  it closes that tab, as today. Such a window lists only its tab.
- **A private window** is a Space of its own that is never saved and never listed: its tabs go with it, as today.

## In the code

`Space` and `SpacesSession` (SunsetPane) are values. At run time a `SpaceModel` (SunsetShell) holds a Space's tabs and
the content of their panes, as `FavoritesModel` holds the Favorites'; a `TabsModel` stays one window's, and its
`workspace` is the Space's tabs with that window's selection: a change made in one window is written to the Space and
read by the other windows that show it, each keeping a selection that still exists (`tabsChanged`).

A window starts with a Space of its own and joins the app's (`TabsModel.join`) when the presentation lists tabs. A
content is wired to the window that draws it (`wireContent`, on `claim`): what it asks of a window (a link to open, the
font) is asked of that one. What ends by itself is closed by the Space (`ended`), whichever windows are left.

## The file

Version 3. Versions 1 and 2 are read and become one Space: the windows' tabs one after the other in the order of the
windows, the Favorites, and one view for each window with the selection it had.

```
{ "version": 3,
  "spaces":  [ { "id", "name", "icon"?, "profile"?, "look"?, "favorites": {…}, "tabs": { "items": […] },
                 "contents": [ { "pane", "kind", "state" } ] } ],
  "windows": [ { "space", "selected"?, "entry"? } ] }
```
