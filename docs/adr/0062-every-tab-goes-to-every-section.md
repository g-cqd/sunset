---
status: accepted
date: 2026-11-17
---

# 0062 — Every tab goes to every section of the sidebar, in order; a split goes whole; a folder stays in the Favorites

The owner, 2026-11-17 (roadmap 0035 A): "all tabs should be movable to all sections, split dragging a tab from a split tab
container should drag the container itself to whatever section. current drag and drop fails to reorder pinned tabs, and
does not also work for favorites, all tabs and all kinds should be movable across all sections, with the exceptions of
folders that can only be moved within favorites".

## What was wrong (each a red test in `TabsSectionDropTests`)

- A tile of the Pinned grid could not be put in another order: the grid took a drop only as "pin this", which a tile
  already was.
- A tile dropped on a favourite's row was moved in the Favorites' tree, where it was not: nothing happened. On the
  Favorites' line, which was outlined for it (ADR-0057), it was refused.
- A pane of a split's row could go to neither the grid nor the Favorites, and among Today's tabs it left its split.
- A folder could be dropped among Today's tabs (nothing happened).

## Decision

1. **One place type for the three sections** (`SectionDrop`: the grid, the Favorites in a folder, Today, each at a
   place) and one pair of calls (`canDropDragged(in:)`, `dropDragged(in:)`) that every drop place in the sidebar goes
   through: the grid's tiles (by halves, leading and trailing), the grid's empty slot, a favourite's row (by halves), a
   folder, the Favorites' line, Today's rows, and a new place after Today's last tab, shown while something is dragged.
2. **What can go where**: a tab of Today, a split, a favourite and a tile go to each section, at the place dropped; a
   document as before; **a folder moves within the Favorites only**, never into itself.
3. **A pane dragged from a split's row carries its split**, to every section and in Today's order. Dropped on a row's
   middle or on a pane it still joins it, as before; "Move Pane to Its Own Tab" still takes one out.

## Not done

- Not seen: no drag can be made by the agent's tools; the model is tested, the views' drop places are not.
- A drag from one window dropped in another: taken since roadmap 0036 F (a tab of another Space comes to the window's).
- Several rows marked and dragged together keep their paths of before (onto the grid, a folder, a row, the line).
