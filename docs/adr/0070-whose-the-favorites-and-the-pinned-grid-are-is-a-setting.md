---
status: accepted
date: 2026-11-18
supersedes: ADR-0055's point 1 as the default (the Favorites the profile's), which becomes a choice; ADR-0053's grid, which can be shared by every profile
---

# 0070 — Whose the Favorites and the Pinned grid are is a setting

## What asked for it

The owner, 2026-11-17 (evening; roadmap 0044): "for spaces of the same profile there's no reason to scroll the pinned
tabs, only the favorites and tabs of the spaces should change … by default, pinned tabs are by profile, favorites are by
spaces and tabs are by window and or spaces (we could have settings for that)".

## Decision

1. **`spaces.favorites`**: `space` (default: each Space has its own list) or `profile` (ADR-0055: one list for the Spaces
   of a profile). **`spaces.pinned`**: `profile` (default, ADR-0053) or `app` (one grid, the first profile's, for all).
2. **Read once, when Sunset opens** (`AppSpaces.ownership`); Settings say "Takes effect the next time Sunset opens". A
   live change would move running panes between lists while windows draw them; not worth it for a setting set once.
3. **Nothing kept is lost when the setting changes.** The session is read the way the setting says
   (`SpacesSession.Ownership`): by Space, a profile's list goes to the first of its Spaces, put together with what that
   Space had (`Favorites.merge`); by profile, the Spaces' lists go to their profile as ADR-0055 says. With one grid, the
   other profiles' grids join the first's, after it.
4. **A Space's own Favorites go with it**: through a change of profile they stay; when it is deleted they go, running,
   to where its tabs go (folders put together with the target's, what was open in them closed), or close with it; the
   question on deleting is asked when it has tabs or Favorites.
5. **The swipe follows the choice**: a part of the list the two Spaces share (the grid of one profile, or of the app;
   the Favorites of one profile) stays still; the rest slides.
6. **A shared grid is never closed with a profile**, and is saved once, with the first profile.

## Consequences

- `SpaceModel.ownsFavorites`; `SpacesModel(ownership:)`; `ProfilesModel(sharesPinned:)`.
- The default changes what a session of before shows: the profile's Favorites appear in its first Space only.

## Not done

- `spaces.tabs` (a window's own tabs within a Space): roadmap 0044 D.
- A Space's Favorites cannot be copied to another Space in one step.
