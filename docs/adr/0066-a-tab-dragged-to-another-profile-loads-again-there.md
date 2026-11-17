---
status: accepted
date: 2026-11-17
---

# 0066 — A tab or a kept entry dragged into a window of another profile moves there, and its pages load again as that profile

The owner, 2026-11-17 (roadmap 0037 B), asked what a tab or a favourite dragged into a window of another profile should do,
knowing its pages carry the first profile's cookies and logins: "Move, reload".

## Decision

1. **A tab** of another profile's Space comes to the window's Space at the place dropped (Today, the Favorites, the grid);
   **its pages are made again** from where they were (their address and history), as that profile, as when a Space is
   given another profile (ADR-0053, `SpaceModel.restart`, now for chosen panes); a terminal, a document run on as they are.
2. **A kept entry** of another profile (a favourite, a tile) leaves it, as a tab, then goes where it is dropped, as a tab
   of the other profile does.
3. A folder still stays in its Favorites (ADR-0062).

## Not done

- Not seen on screen.
