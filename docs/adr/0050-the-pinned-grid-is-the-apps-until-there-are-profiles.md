---
status: accepted
date: 2026-11-17
---

# 0050 — The Pinned grid is the app's until there are profiles

R4 put a grid of pinned icons at the top of the sidebar and gave it to the profile, after profiles. The owner asked for
it earlier (2026-11-17: "pinned grid, chrome impersonation and then profiles"), and answered what that left open.

## Decision

| Question | The owner's answer |
| --- | --- |
| Whose grid, before profiles | **One for the app**, the same in every Space; per profile later, his going to the first profile |
| How something is pinned | By its menu, and by **dragging its row onto the grid**; the tab **moves** there. "I'd like that the moving to be animated and an invisible placeholder slot is allocated for the being moved tab" |
| How many, in what shape | "Up to 3x4 items or 4x3": **twelve at most**, four columns; "depending on the size of the sidebar, we could down to 2 columns or even 1" |
| The tiles | Icon only, sharing the width: "not necessarily a square, but with a max and min width, as well as height obviously" |
| A tile that is loaded | "Active pinned tabs should have a stroke (that does not expand their size) that is visible when active, and invisible when not loaded": **a line inside the tile** (the pane's hairline, stronger; the accent's colour for the one shown) |
| The tiles' corners | "Corner radii should be the same than for tabs": **a tab row's corner** (`layout.tabRadius`, continuous) |
| A pinned page that was navigated away | A click shows it where it is; "the reset to where it started should happen in a context menu item" |

Decided by the builder, to be said:

1. **A pinned entry is a kept entry**, as one of the Favorites is (R4): shown instead of a tab, unloaded by Cmd-W and
   kept, drawn in one window at a time, started again from where it was pinned. The grid is a second `FavoritesModel`
   with no folders; a window asks which of the two keeps an entry (`TabsModel.keeper(of:)`).
2. **The tile's measures** (`PinnedLayout`): 36 points high, between 40 and 120 wide, 6 apart. Four columns while each
   has 40 points; then three, two, one.
3. **Its menu**: Show or Open, Reset to Where It Was Pinned, Unload, Rename, Change Icon…, Unpin (it is a tab again,
   running), Delete. Pin is in a tab's menu, and "Pin or Unpin Tab" in the menu bar acts on what the window shows.
4. **The session keeps it beside the Spaces** (`pinned`), and it holds its panes before any Space does.
5. **A private window has no grid.** A window that is one tab has the grid's model but no sidebar to show it in.

## Not done

- **A favourite cannot be pinned directly** (only a tab can), and the grid is not reordered by dragging.
- **The drop slot is one more tile at the end**: it does not open where the pointer is.
- R4's "pinned entries that are open are never unloaded by the delay" waits for the sleeping step (S-e).
- The built-in tab bar (no sidebar) does not show the grid.
