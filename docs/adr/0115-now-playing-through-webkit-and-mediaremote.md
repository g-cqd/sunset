---
status: accepted
date: 2026-11-22
---

# Now Playing reads pages from Sunset's world; previous and next through MediaRemote; macOS's picture in picture

## Context

The owner asked (2026-11-22) for cards of what plays at the foot of the sidebar, each with play and pause, previous and
next, mute and Go There, and for picture in picture. What WebKit tells and allows was probed (diary 2026-11-22-06): one
now-playing session per process; per page, whether it plays sound (`_isPlayingAudio`, observable) and its media, read
from Sunset's content world; play and pause through the page's own handlers; mute by page; previous and next only
through the system's media commands (MediaRemote), which reach whichever app played last; which app that is cannot be
asked.

## Decision

- **What a card shows** is read per page from Sunset's content world (`navigator.mediaSession.metadata`, the media
  elements), never from the process-wide session, and never by a script in the page's world (ADR-0089). Short UI or
  notification chimes (audio under 5 seconds without `MediaSession` metadata, or Web Audio bursts under 3 seconds) are
  ignored, and a card with no paused track is removed as soon as sound stops.
- **Play, pause** go through WebKit's session calls, so the page's own handlers run; **mute** is the page's.
- **Previous and next** pause and play the card's media from Sunset's world, which makes the page the system's now
  playing again, then send the command through MediaRemote. Chosen by the owner, with the gap of a moment it makes.
- **Picture in picture** is WebKit's own, the system's window (chosen by the owner over a window of Sunset's).
- Both features are behind settings, on by default.

## Consequences

- An app that starts playing in the instant between the pause-play and the command gets it.
- MediaRemote and WebKit's session calls are private: looked up by name, each guarded, a missing one hides its button.
- The system window of picture in picture has Apple's controls: no mute, not maximisable.
- Sunset WebKit could take a patch that sends an action to one page, ending the pause-play.
