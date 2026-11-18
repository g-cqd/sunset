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
| A | A swipe between Spaces of one profile leaves the Pinned grid still; only what is the Space's slides | done: `sharesPinned`, the grid apart from the Favorites in the list (test; a swipe not seen) |
| B | `spaces.favorites`: `space` (default) or `profile`. Per Space: each Space its own list; a session of before (profile's) gives its list to the profile's first Space, not a copy to each (a copy would be two entries, ADR-0055's reason) | done 2026-11-18 (ADR-0070; tests) |
| C | `spaces.pinned`: `profile` (default) or `app`, one grid for all profiles | done 2026-11-18 (ADR-0070; tests) |
| D | `scopes.tabs`: `space` (default) or `window` (a window has its own tabs in a Space, as a window that is one tab does) | not-started |
| E | Settings > General > Spaces, a topic of help, the swipe and the menus following each choice | done but menus and screen: the settings, the "Spaces" topic and its "?", shared Favorites still in a swipe (tests); no menu needed changing; Settings and the topic seen 2026-11-18; a swipe with each choice not seen |

The settings are read when Sunset opens (ADR-0070, point 2).

## Not done

D (`spaces.tabs`); a swipe with each choice, seen.
