---
status: accepted
date: 2026-11-19
---

# 0086 — One owner for each decision: the causes of the bugs of 2026-11-18 and 19

## Context

The owner (2026-11-19): "for all bugs you fixed, you need to fix the causes not the symptoms … refine architecture even if
necessary". Read back over the bugs fixed since 2026-11-16, most had one cause: a decision made in several places, or made
as a side effect where something else should own it.

## Decision

| Decision | Its one owner | Bugs it caused before |
|---|---|---|
| A page's view ends | `WebContent.endView` (closed tab, unload, Reload As): media suspended, out of its window, page closed | n54: a closed tab played on while its view was held |
| Who holds a page's view | Its host, except while WebKit has it for full screen (`WebViewHostView.takesBack`) | n53: full screen empty |
| Who has the keyboard | The focused pane, except from a text field being edited (`PaneKeyboard`) | A rename ended when its page loaded again |
| Whether a page asks for its address | The action that makes a new empty page (the command bar for a tab; a window of its own) — never the view | n52: the page's bar came out with the command bar |
| A page's settings | `PaneContentKinds.pageSettings(profile:privacy:)`: its profile's own over all profiles', its profile, its privacy | A kept page reloaded as another profile took the wrong settings; a settings change dropped a profile's own |
| A click and a double click on a kept entry | The same gestures for a tile and a row, then `select(entry:)` and `doubleClick(entry:)` | n7 twice: the tile's button took the clicks, and a timer stood in for the double click |
| Where a link from the page's menu opens | The item chosen, as it runs (not the menu's close, which comes after WebKit asks) | n51: every link opened as a tab |
| Screen capture | Sunset, through macOS's picker (ADR-0085); WebKit's own refused | Nothing native shown; a screen taken unasked |

## Consequences

- A new path that ends a view, places one, takes the keyboard, asks for an address, or makes page settings goes through
  its owner; the tests named in the diary of 2026-11-19 (02) hold each.
- Removed: `leaveAddressToBar` and the flag behind it, `clickTile` and its timer, the per-call settings in `make` and in
  `WebProfiles.settings`, the three copies of a view's teardown.
- Not seen on screen (no accessibility for the terminal the work was done from): the tile's clicks especially, which the
  owner reported twice.
