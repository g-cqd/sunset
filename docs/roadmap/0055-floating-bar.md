---
status: in-progress
blocked-by: nothing
date: 2026-11-18
---

# 0055 — A floating bar when the sidebar is off

The owner's notes n41, n42 (2026-11-18) and his answers: with the sidebar off, the tabs, the address and the page's actions
are glass over the page at the chosen edge, the page full height under them; hidden until the pointer reaches the edge by
default, a switch keeps them shown. Shown always, the space under the bar is either a native toolbar, or the page's own
background (its colour and theme) under the fading blur. The groups stay separate containers (tabs, address, actions), as
before. The page's own address row ("At the top of every page") stays, floating over the page and revealed at its top.

| Step | What | Status |
|---|---|---|
| A | The built-in bar over the page, not above it: the page full height (`FloatingEdgeBar`), the area keeping the window's corners | done |
| B | Hidden until the pointer reaches the edge (a 6 pt strip), gone 0.4 s after it leaves, out while its address is typed in (`EdgeReveal`); `tabs.bar.autoHide` (on) | done; the reveal not seen (a hover cannot be given) |
| C | Shown always: the bar's tint fading into the page over the fading blur, its controls in the tint's scheme | done (seen); a native toolbar instead: not done |
| D | The page's own address row floats over its top, revealed there | not-started |

Not done: D; C's native toolbar; the window bar (address in its own bar, `web.address` window with tabs not built in) already floated and hid before this.
