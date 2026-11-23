---
status: in-progress
blocked-by: nothing
date: 2026-11-22
---

# 0114 — Now Playing cards and picture in picture

The owner's notes of 2026-11-22: a stack of cards at the foot of the sidebar for what plays (one prominent, the tops of
at most two more behind it in perspective; scrolling goes through them); a card has the site's icon or a picture of what
plays, play and pause, previous and next, mute, and Go There (the tab, in its Space and window). Picture in picture for
videos, in a window with no chrome, its controls on hover (back to the tab, play and pause, seek, back and forward, mute),
maximisable. Each behind a switch in Settings.

| Step | What | Status |
|---|---|---|
| A | Probe what WebKit tells and allows (diary 2026-11-22-06) | done 2026-11-22 |
| B | The model: what plays in each page, the stack's order, the card's actions; platform-free, tested | done 2026-11-22: `MediaStack`, `MediaStackScroll` |
| C | Reading a page: playing and session observed (KVO), metadata and media read from Sunset's world | done 2026-11-22: `NowPlaying`, `MediaReading` |
| D | The actions: play and pause, mute, previous and next (pause-play, then MediaRemote: ADR-0115), Go There | done 2026-11-22, tested but for Go There and a real media command |
| E | The stack at the foot of the sidebar; the switches `web.nowPlaying`, `web.pictureInPicture` | built 2026-11-22, not seen |
| F | Picture in picture: macOS's own, through WebKit (ADR-0115) | built 2026-11-22 (WebKit's toggle, else the video's presentation mode from Sunset's world), not seen |

The owner's note of 13:34 answered 2026-11-22: the stack goes round, the way back from picture in picture shows the tab, the cards are redrawn (window's material, the ones behind blank, Control Center's layout, animated, a scrolling title). Seen on screen 2026-11-22 (test copy, build 735): picture in picture has its controls, for a local video and YouTube; its way back returns the video to its page; the card's title scrolls. Not done: the owner's case without controls (build 728) not reproduced; seen on screen (the stack, its scroll, Go There, picture in picture, a real next and previous). The artwork is not shown: fetching it outside the page's store would go around its profile; the card shows the site's icon. A media in a frame (an embedded player) plays and is paused through WebKit's session, but previous and next cannot replay it first, and its title is the page's.

## 2026-11-23 — the owner's notes n123 to n126

- n123: a card follows its page's mute at once, wherever it was muted from.
- n124: `web.autoPictureInPicture` (off by default, under Media): a playing video floats when its tab is left and comes back
  when the tab is shown; only one Sunset floated comes back. The cards keep their picture in picture button. Not seen in
  the app: whether WebKit lets a video float without a click there.
- n125: cards have the window's hairline edge; a scroll turns one card a gesture (its momentum ignored), a mouse wheel's click
  one card. Not seen in the app.
- n126: picture in picture reaches a video in a frame of its own (Fox News); cnews.fr not reproduced (no video before play
  or consent).
