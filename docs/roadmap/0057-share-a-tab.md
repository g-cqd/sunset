---
status: done
blocked-by: nothing
date: 2026-11-18
---

# 0057 — Share a Sunset tab in a call (ADR-0082)

| Step | What | Status |
|---|---|---|
| A | Probe: frames of a page into another page's stream, measured | done (ADR-0082) |
| B | The wrapper of `getDisplayMedia` in every page (not private ones); Sunset's sheet (tabs by Space, other profiles by `web.shareOtherProfiles`, Screen, Window or App…) | done (seen) |
| C | The frames of a web tab, pipelined, 30 fps at most, 1920 pt wide at most; a tab never shown made and drawn in a window off screen | done: a call page received 145 frames in 5 s at 1280×800 from a tab never shown |
| D | Terminals (a frame drawn on demand, shown or not; one never shown is not offered: no shell yet) and documents (drawn again from their rows) as sources | done: a hidden terminal shared, 108 frames in ~4 s at 996×908; documents not seen |
| E | Policy: the shared tab marked (its orange dot), stops when either closes or the shared page goes to another site, stopped from the call's site panel, the page, or the shared page's own panel (Stop Sharing This Tab); `TabShareTests` | done; the source closing not seen (the requester closing seen) |

Not done: a page never loaded is listed by its host, not its saved title; a terminal or document shared has no mark on its tab (pages do); sites that refuse a canvas's stream not tried (Meet, Zoom, Teams).
