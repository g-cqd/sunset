---
status: accepted
date: 2026-11-17
---

# 0057 — While something is dragged, the places that would take it show

The owner, 2026-11-17: "when dragging, we might want that the target area show so that we know where to drop tabs".

## What was wrong

A drop place showed only under the pointer. Worse: the Pinned grid was not there at all while it was empty, though a
tab could be dropped there: whether to show it was read from what was being dragged, which no view observed, so the
grid never appeared during a drag. And SwiftUI says nothing of a drag dropped where nothing takes it: what was dragged
was remembered until the next drag.

## Decision

1. **A drag is known from its start until it ends** (`TabsModel.dragTargets`): set when a row, a tile or a pane starts
   to be dragged, with where it could go (the Pinned grid, the Favorites, the panes); cleared by a drop, or when no mouse
   button is down any more (checked every tenth of a second while the drag lasts).
2. **Each place that would take it is outlined** at once, in the accent's colour, dashed (`DropTargetOutline`); under the
   pointer it is filled and the line is full:
   - **the Pinned grid**, even empty, with the slot where the tile would land;
   - **the Favorites**: the line under them opens into a row, "Keep in Favorites";
   - **each pane** that would take it; the one under the pointer shows where the new pane would sit, as before.
3. Drawn inside each place's bounds: nothing moves when a drag starts, but the Favorites' line, which becomes a row.

## Not done

- The gaps between tabs in the list, and a Space's icon, are not outlined (a tab cannot be dropped on a Space's icon
  yet).
- **Not seen**: no drag can be made in the background. The model is tested (`TabsDragTargetsTests`); the outlines are not.
