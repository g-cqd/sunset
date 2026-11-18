---
status: done
blocked-by: nothing
date: 2026-11-18
---

# 0054 — A click says what it did

The owner's note n11 (task t36): "a interaction/onclick animation or visual cue that the link is copied when clicking on the
copy link in the address bar, same goes for all buttons of the app, … UX/UI and haptic feedback when relevant as to when a
click goes through or is blocked for some reason".

| Step | What | Status |
|---|---|---|
| A | `ActionFeedback` (done, or blocked and why), `Feedback.give` (the trackpad's tap: light when done, firmer when blocked; VoiceOver's announcement) | done |
| B | Every copy through `Clipboard` (gated): the address bar, its menu, the command bar, history, downloads, a document's link, the recovery code | done |
| C | `FeedbackGlyphButton` (check, or a cross that shakes) for the address bar's Copy; `FeedbackButton` (its title becomes what was done) for the recovery code's Copy | done; not seen |
| D | Glyph buttons give a little while pressed (sidebar's and rows') | done; not seen |
| E | A refused drop says so (`Feedback.dropped`, gated); a menu item that cannot act stays dimmed, as macOS has it | done |
| F | `appearance.haptics` turns the trackpad's taps off (Window › Title bar and buttons) | done |

Not done: nothing of C, D and E was seen on screen (the owner tries them).
