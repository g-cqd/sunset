---
status: in-progress
blocked-by: nothing
date: 2026-11-18
---

# 0057 — Share a Sunset tab in a call (ADR-0082)

| Step | What | Status |
|---|---|---|
| A | Probe: frames of a page into another page's stream, measured | done (ADR-0082) |
| B | The wrapper of `getDisplayMedia` in every page (not private ones); Sunset's sheet (tabs by Space, other profiles by `web.shareOtherProfiles`, Screen, Window or App…) | done (seen) |
| C | The frames of a web tab, pipelined, 30 fps at most, 1920 pt wide at most; a tab never shown made and drawn in a window off screen | done: a call page received 145 frames in 5 s at 1280×800 from a tab never shown |
| D | Terminals and documents as sources | not-started |
| E | Policy: the shared tab marked (its orange dot), stops when either closes or the shared page goes to another site, stopped from the call's site panel (Stop) or by the page; `TabShareTests` for the rules | done but: Stop from the shared tab itself not yet; the source closing not seen (the requester closing seen) |

Not done: D; stopping from the shared tab; a title for a tab never loaded (its host is shown).
