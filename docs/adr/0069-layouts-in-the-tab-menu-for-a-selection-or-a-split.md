---
status: accepted
date: 2026-11-17
supersedes: 0068
---

# 0069 — Layouts are in a tab's menu, for several tabs selected or a split

## Context

ADR-0068's fourth light did not work for the owner (2026-11-17): "we should have that as options on the context menu";
"it should not show when using context menu on only one tab … one should select multiple tab … or context menu on split
tab container"; in white or black by the menu's scheme, not the accent; and the shown tab among several selected must still
look selected.

## Decision

- No fourth light. A tab's menu (a row, or a part of a split) starts with a palette of layouts (`TabLayoutMenu`, SwiftUI's
  `.palette` control group, which draws as the system's own row of pictures at a menu's top), tinted `.primary`.
- It acts on the tabs selected with the row when there are several, or on the row's own tab when it is a split; for one
  plain tab it is not in the menu at all. Only the layouts of as many panes as those tabs hold are offered: two (side by
  side, stacked), three (three columns, one large and two stacked), four (grid).
- A layout makes those tabs one, where the first of them is in the sidebar, their panes in the sidebar's order; it is shown
  and the selection is cleared.
- Among several selected, the shown row is drawn in the selection's accent, stronger than the others (`RowEmphasis`); a
  split's row now shows that it is selected too.
- Private API to put the pictures in the menu was not needed: `.palette` is public (macOS 14).

## Consequences

- Five panes or more have no layout.
- Not seen on screen: the palette with a real selection (axdrive cannot ⌘-click; the person's pointer was not taken).
