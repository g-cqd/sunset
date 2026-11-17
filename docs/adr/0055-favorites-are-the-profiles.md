---
status: accepted
date: 2026-11-17
supersedes: R4's "a Space holds its Favorites"; ADR-0047's "a new Space starts with a copy of the Favorites"; point 4 of ADR-0047 for the Favorites (a deleted Space's)
---

# 0055 — The Favorites are the profile's, the same in each of its Spaces

## What asked for it

The owner's note n80: "tabs open in a profile should show active in every space of the said same profile, and appear
as such in the sidebar on all spaces, goes for pinned and favorites". The Pinned grid was already the profile's
(ADR-0053). The Favorites were each Space's, and a new Space had a *copy* of them (his answer of the same morning,
ADR-0047): a copy and its original are two entries, and one being open did not show on the other. Asked which way to
make them one, he chose: **"Favorites become the profile's"**.

## Decision

1. **A profile has one list of Favorites**, shown in every Space of the profile, as its Pinned grid is. What is open in
   it is open in all of them, and is drawn in one window at a time, as before. Only the Tabs are a Space's.
2. **A new Space has no Favorites of its own to start with**: it shows its profile's. Nothing is copied.
3. **A deleted Space takes no favourite with it.** The question on deleting is about its tabs only, and is asked when it
   has tabs.
4. **A Space given another profile shows that profile's Favorites.** A window that showed a favourite of the profile it
   leaves stops showing it; the favourite is not closed.
5. **A removed profile's Favorites are removed with it**, as what it had pinned (the question says so).
6. **A session of before** had Favorites in each Space. They go to the Space's profile, in the order of the Spaces,
   put together (`Favorites.merge`): a folder of the same name is one folder; an entry that looks like one already there
   (the same name, icon, command and what it starts from: what a copy shares with its original) is that entry, and of
   the two the open one is kept. What is kept holds its panes before any Space's tab does.

## Consequences

- R4's sentence "what moves is the tab, its Favorites stay with the Space" is void: there is nothing of a Space's but
  its tabs, its name, its icon and its colour.
- `Favorites.copied()` and the copy made by `SpacesModel.add` are gone.

## Not done

- Each Space cannot hide or reorder the profile's Favorites for itself: one list, one order.
- A favourite cannot be sent to another profile (it can be unkept there and kept again here).
