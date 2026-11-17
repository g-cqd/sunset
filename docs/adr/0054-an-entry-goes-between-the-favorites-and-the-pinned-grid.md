---
status: accepted
date: 2026-11-17
---

# 0054 — An entry goes between the Favorites and the Pinned grid as it is, and every menu says where it can be kept

## What asked for it

The owner, on trying the Pinned grid (ADR-0050): "the context menus of tabs and sidebar don't contain all features
related to pinning and marking as favorites and i fail to set an already favorites tab as a pinned tab".

He was right on each count. ADR-0050 said "a favourite cannot be pinned directly" as a thing not done; a favourite's
menu had nothing about pinning; a tile's menu had nothing about the Favorites; a single tab's menu had no Move to Space;
the built-in tab bar's menus had less still and the bar did not show what was pinned. And one thing nobody had seen: a
single tab's row dragged onto the grid was never pinned (only a marked selection was), though ADR-0050 said it was.

## Decision

1. **A kept entry is the same entry wherever it is kept.** Pinning a favourite, or making a pinned entry a favourite,
   moves the entry itself (`FavoritesModel.give`): its id, name, icon, command and seal, what it starts from; open, its
   content runs on and the window that shows it goes on showing it.
2. **One menu for a kept entry** (`KeptEntryMenu`), the same on a favourite's row, a tile, and a tab of the built-in bar:

   | Group | A favourite | A pinned entry |
   | --- | --- | --- |
   | Showing | Show, or Open | the same |
   | Where it is kept | Pin; Remove from Favorites | Unpin; Move to Favorites |
   | What it is | Rename; Change Icon…; Edit Command…; Run Command Now | the same |
   | Where it starts | Reset to Home; Set Home to Current; Unload | Reset to Where It Was Pinned; Pin Where It Is Now; Unload |
   | | Delete | Delete |

3. **One group for a tab** (`TabKeepMenu`), in the sidebar's row and the built-in bar's tab: Pin; Add to Favorites; New
   Folder with This Tab; Move to Space (once there are two).
4. **Several rows selected**: "Pin N" beside "Add N to Favorites", for the tabs and favourites among them.
5. **The menu bar**: "Pin or Unpin Tab" pins the tab or the favourite shown and unpins a pinned entry; "Add to or Remove
   from Favorites" keeps the tab shown, takes a favourite out as a tab, and makes a pinned entry a favourite.
6. **Dragging**: a tab's row or a favourite's row dropped on the grid is pinned (one row, or the rows marked); a tile is
   dragged out, onto the Favorites (it is a favourite there, in the folder and at the place it is dropped) or onto the
   tabs (a tab again).
7. **Resetting asks first** when something runs in the entry, as unloading does; a tile asked about is outlined in red,
   as a tab's row is.
8. **With the built-in tab bar** what is pinned is shown as icons before everything else in the bar.

## Not done

- A folder is not pinned (the grid has no folders); pinning the rows of a selection leaves folders where they are.
- Tiles are not reordered by dragging within the grid.
- The two menu bar items do not say which of their two things they will do.
