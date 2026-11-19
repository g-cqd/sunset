---
status: accepted
date: 2026-11-19
supersedes: roadmap 0035 F (its decision: only Today's tabs scroll)
---

# 0088 — The sidebar's Pinned grid, Favorites and tabs scroll as one

## Context

Roadmap 0035 F (the owner, 2026-11-17): "Scrolling for tabs should only happen for today's tabs not pinned and favorites".
The grid and the Favorites kept their height (`layoutPriority(1)`), and Today's scroll view took what was left.

The owner's note n56 (2026-11-19): "contrary to a previous decision, we should make the whole favorites and tabs scrollable
at once and even the pinned tabs if necessary because of the size because if the window height becomes very small, then
... things overflow the screen, and what is meant to stay at the bottom or the top is not shown and accessible anymore".

Probe (`SidebarScrollTests`, a sidebar 180 pt tall with a pinned tab, six favourites and three tabs): the scroll view began
at 244 pt, below the window: the grid and the Favorites pushed everything after them out.

## Decision

One scroll view holds the Pinned grid, the Favorites and Today's tabs. It takes the height the header and the bottom bar
leave; neither is ever pushed out. The swipe between Spaces still moves each part on its own (a part both Spaces share stays
still), and the ends still fade.

## Consequences

- In a tall window nothing changes on screen (drawn before and after: the same).
- Scrolling the list moves the grid and the Favorites away too; the owner's reason for 0035 F (they stay in view) holds
  only while the window is tall enough, which is when nothing scrolls.
