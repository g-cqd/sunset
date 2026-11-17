---
status: in-progress
blocked-by: nothing
date: 2026-11-17
---

# 0044 — Whose the Pinned grid, the Favorites and the tabs are, as settings

The owner, 2026-11-17 (evening): "for spaces of the same profile there's no reason to scroll the pinned tabs, only the
favorites and tabs of the spaces should change … by default, pinned tabs are by profile, favorites are by spaces and tabs
are by window and or spaces (we could have settings for that)". This turns ADR-0055 (Favorites the profile's, his choice
of the morning, n80) into a setting whose default is now the Space.

| Step | What | Status |
|---|---|---|
| A | A swipe between Spaces of one profile leaves the Pinned grid still; only what is the Space's slides | not-started |
| B | `scopes.favorites`: `space` (default) or `profile`. Per Space: each Space its own list; a session of before (profile's) gives every Space of the profile a copy of it, kept open where it was in the first | not-started |
| C | `scopes.pinned`: `profile` (default) or `app`, one grid for all profiles | not-started |
| D | `scopes.tabs`: `space` (default) or `window` (a window has its own tabs in a Space, as a window that is one tab does) | not-started |
| E | Settings > General > Spaces, a topic of help, the swipe and the menus following each choice | not-started |

## Not done

Everything above.
