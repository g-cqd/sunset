---
status: not-started (notes taken 2026-11-11 to 2026-11-12; four already done)
blocked-by: nothing for A and B; C to E after the web milestone (0019) by the owner's order of building
date: 2026-11-12
---

# 0028 — The shell's polish, from the owner's notes

The owner's notes n49 to n67 that are not part of a roadmap step yet. Each step starts with its own questions to the owner. The rule of
`docs/design/0002-spacing.md` holds throughout: when two gaps must match, the smaller grows.

## Done already

| Note | What | Commit |
| --- | --- | --- |
| n58 | A tab's hover preview in the window's proportions, each pane filling its spot | 522da7e |
| n62 | A web tab has one line (the address is in the address field) | 82f98d6 |
| n63 | The glyph is as far from the text as from the row's edge (7 pt gap) | 82f98d6 |
| n64 | Not Secure as the lock alone, its words on hover | 82f98d6 |
| n65 | A row's title takes the close button's room while the button is hidden | e5ba931 |
| n55 | A split kept entry drawn as a split tab (to confirm with the owner; the built-in bar's folder chips not done) | 522da7e |

## Steps

| Step | What | Notes | Task |
| --- | --- | --- | --- |
| A | Spacing of a row: top and bottom padding visually equal to the leading padding before the glyph; the same measures in the sidebar, the tab bar, the command bar and the address list | n66 | t214 |
| B | The history panel rebuilt on the sidebar's own parts: the header's inset under the window buttons, the same side insets, rows, states, fade and look | n67 | t215 |
| C | The bars (window address bar, command bar, address list, find bar): background through Aemi's variable blur; corners concentric, inner padding and spacing between items reviewed | n60 | t208 |
| D | A page tab's loading as a ring that completes, with a rounded end; the favicon clipped inside it, then becoming the icon (initial in a square, favicons with slightly rounded corners, clipped). Brings the favicon setting of R1 | n61 | t209 |
| E | Animation when a dragged tab lands in the sidebar or the tab bar | n54 | t203 |
| F | A font of its own for tab labels (terminal tabs, maybe monospaced) | n53 | t202 |
| G | Split presets for a tab (halves, thirds, grids) | n49 | t199 |
| H | Reordering everything in the sidebar, dragging into folders, nested folders and Pinned (with 0020's and 0021's steps) | n51 | t201 |

## Studies, read back to the owner before anything is built

| Study | Notes | Task |
| --- | --- | --- |
| Safari's tab controls and look, to use system parts where we rebuilt them | n50 | t200 |
| How Apple structures settings (System Settings, Safari with its profiles, Xcode), to reorganise Sunset's | n57 | t206 |
| Why switching, focusing and closing tabs is slow: measured with signposts first, then fixes proposed | n56, n59 | t205 (also 0026's performance work, t100) |

## Order proposed

A and B first (small, and B depends on A's measures), between web steps f and g if the owner agrees; C and D together after the web milestone
(both touch the bars and the tab's look); the measurement of t205 as soon as the screen is free; the rest by the owner's order.
