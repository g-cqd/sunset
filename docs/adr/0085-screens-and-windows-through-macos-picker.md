---
status: accepted
date: 2026-11-19
supersedes: 0082 (decision 1, its last sentence, only)
---

# 0085 — A screen, a window or an app: macOS's picker, captured by Sunset; WebKit's own capture never allowed

## Context

ADR-0082 gave "Screen, Window or App…" to WebKit's own `getDisplayMedia`, expecting macOS's picker. The owner (2026-11-19):
"clicking on screen and windows i'd expect to get the native experience then, but that's not what's happening".

## Evidence (probes, this Mac, `/tmp/gdm`, `/tmp/pickprobe`)

| Probe | Result |
|---|---|
| A WKWebView, screen capture on, `getDisplayMedia` called 1.5 s after the script started (as after Sunset's sheet) | `InvalidStateError: getDisplayMedia must be called from a user gesture handler`: the sheet's click is used up |
| The same, called at once, WebKit's private display question answered 1 | No picker: the main screen taken ("Screen") |
| Answered 2 | No picker: a window of WebKit's choosing taken (the terminal's) |
| `SCContentSharingPicker.shared.present()` from a process started in a terminal | The picker shown (a new window of Control Center's) |

## Decision

1. "Screen, Window or App…" shows `SCContentSharingPicker` (a screen, a window, an app). What the person picks is captured
   with an `SCStream` (at most 1920 wide, 30 a second) and reaches the page as a tab's frames do (ADR-0082, decision 2).
   Cancelled, the page is refused (`NotAllowedError`).
2. WebKit's private display-capture question is always answered no: a page that reached WebKit's `getDisplayMedia` by
   another way would otherwise share a screen nobody chose. The page's wrapper no longer keeps WebKit's function.
3. The picker stays active while the share runs (macOS shows it is shared, and can stop it); it is released when the share
   stops by any of ADR-0082's rules.

## Consequences

- No screen recording permission: the picker is the permission, each time.
- The system audio WebKit could add (`withSystemAudio`) is not shared; nothing asked it yet.
- Seen on screen: the picker coming up only; a pick, its frames in a call and the stop were not seen (the terminal had lost
  its screen permissions).
