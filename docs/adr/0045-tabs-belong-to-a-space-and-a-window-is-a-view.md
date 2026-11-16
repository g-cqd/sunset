---
status: accepted
date: 2026-11-16
---

# 0045 — Tabs belong to a Space, and a window is a view of one

R4 (accepted 2026-11-11) said it: "Spaces are app-wide; the same Space can show in several windows; a tab's content is
live in one window". Until now each window had its own tabs. Step S-a had two questions left (ids; whether the order of
Spaces is per window), and making tabs the Space's raised four more, since it changes what a window is. Asked on
2026-11-16; the owner's answers are the decision.

## Decision

| Question | The owner's answer |
| --- | --- |
| One Space, two windows: what the second shows | **The same tabs.** "Clicking a tab already visible in the other [window] switches the control and live rendering to the newly focused one" |
| The order of the Spaces | **One for the app** |
| The last window of a Space closes | **Its tabs stay, stopped**; "a setting should allow to clean open tabs after a delay or when (last) window of a space closes" |
| New Window | **Nothing selected**: "a new window opens and focuses a new empty tab (basically the command bar on a new tab)" |
| Bringing a window to the front | **Takes nothing**: only a click on the tab or on its picture does |
| Roadmap 0033 (scopes turned off) | After Spaces, before profiles |

Decided by the builder, to be said:

1. **Ids** are UUIDs, as tabs and panes have: a Space is renamed without anything that names it changing.
2. **A session of before becomes one Space** whose tabs are the windows' tabs one after the other, in the order of the
   windows; each window becomes a view with the selection it had. The Space's id is made when the file is first read.
3. **Sharing comes before switching.** R4 listed "the same Space in several windows" fourth (S-d). It is the foundation:
   a window cannot change Space until tabs are the Space's. The picture a window shows of a tab live elsewhere is what
   kept entries show today; what it should look like stays S-d's question.
4. **Where there is no list of tabs** (one tab a window, the system's tab bar) a window is one tab of the Space and
   closing it closes that tab: nothing there can show a tab that has no window.
5. **A private window is a Space of its own**, never saved, never listed.
6. **The format keeps what it does not read**: a Space's `look` is carried as it was written, so that an earlier build
   does not strip what a later one wrote.

## Consequences

- The red button no longer ends what runs, unless the window is the last of its Space; and then it stops things without
  forgetting the tabs.
- A tab can have no window. Quitting, and the questions about running commands and unsaved edits, are about the Spaces'
  tabs, not the windows'.
- Until the setting that cleans stopped tabs exists, they stay until closed by hand.
