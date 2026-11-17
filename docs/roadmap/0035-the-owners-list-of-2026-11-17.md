---
status: in-progress
blocked-by: nothing
date: 2026-11-17
---

# 0035 — The owner's list of 2026-11-17: the sidebar's sections, the address field, the web's notifications and icons, staying awake

Asked by the owner on 2026-11-17, as a checklist of ten, with his answers to seven questions (below). One task per step.

## The steps

| Step | What he asked | His answers | Status |
| --- | --- | --- | --- |
| A | "Drag and drop of pinned, favorites and tabs does not work reliably" | Every tab, of every kind, can be moved to every section (Pinned, Favorites, Today) and reordered in it; a pane dragged out of a split tab drags the split itself; folders move within the Favorites only. Today the Pinned tiles cannot be reordered, nor the Favorites | not-started |
| B | "Pinned tabs don't align with edges of other tabs" | — | not-started |
| C | "There is still no preview for regular web tabs" | — | not-started |
| D | "Web notifications don't work with system notifications" | — | not-started |
| E | "A tab or a window keeps the Mac awake as long as it is running" | Both, chosen: until it is closed, or until its command ends; whether the display stays on too is a setting | not-started |
| F | "Scrolling only for Today's tabs, not Pinned and Favorites; the variable blur only an alpha mask" | — | not-started |
| G | "The address field in the sidebar always there, the central place to start a search or create a tab when a terminal is focused, a tab's dimensions" | Also commands: the command bar's results listed under it | not-started |
| H | "A way to cache favicons when tabs are unloaded" | On disk, across quits; cache expiry respected and reloaded accordingly; an icon the page changes while it runs replaces the cached one; done in the background also for a tab set to show an icon of its own, which the favicon never replaces, and to which the person can go back | not-started |
| I | "Calls to action for allowing and authorizing, below the address field" | The pages' permission questions, and what macOS must allow Sunset itself (with a way to System Settings) | not-started |
| J | "Tab focusing for a Space with several windows does not rerender correctly in the new window when switching to it" | A white or black page; not even the last snapshot, only the notice to click to bring it back | not-started |

## Not done

Everything above, until each row says otherwise.

A test failing at the start, before any of this: "a click on a folder folds it at once; a double click renames it and leaves
it as it was" (`SidebarClickTests+Favorites.swift:41`), three runs of three. Reported, not part of this list.
