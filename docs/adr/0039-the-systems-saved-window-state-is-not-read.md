---
status: accepted
date: 2026-11-16
---

# 0039 — The system's saved window state is not read, and Sunset's windows are left out of it

## What asked for it

2026-11-16, while probing M-f: every Sunset signed with the project's identity started with **no window**, the installed
release build included, and its New Window did nothing. AppKit said why in its log:
`_reopenWindowsAsNecessaryIncludingRestorableState: shouldRestoreState=1 hasPersistentStateToRestore=1`. A test copy had been
ended by a signal while it had no window; AppKit had recorded "no windows" for it; and that record is kept per signing
identity (`~/Library/Daemon Containers/<id>/Data/Library/Saved Application State/<id>.savedState`), so every copy of Sunset
read it at its next start and restored exactly that. A copy signed ad hoc, which has another record, started normally; so
did the same build given `-ApplePersistenceIgnoreState YES`. A clean quit removes the record.

The same record is t263: while Sunset runs it holds each window's title in plain (a folder, a file's name, a page's
title), outside the sealed store, and stays after a kill or a crash (white paper §9).

Sunset restores its own session, from its own store. The system's record gives it nothing and can take its window away.

## Decision

1. **The record is not read.** `SystemRestoration.ignoreSavedState()` puts `ApplePersistenceIgnoreState` in the argument
   domain of the defaults before the application object exists: what the command-line flag says, however Sunset was started.
2. **Sunset's windows are left out of it.** `NSWindow.isRestorable` is set to false on every window as it comes on screen or
   takes the keyboard, AppKit's own panels included.
3. **A Sunset with no window can always make one.** The menus say how a window is opened (`AppActions.opensWindows(with:)`)
   until a window has said it itself: New Window, New Tab, the settings and a file opened from the Finder no longer depend
   on a window having existed.
4. **The window's frame is still the system's to remember.** `.restorationBehavior(.disabled)` on the `WindowGroup` was
   tried and rejected: it also drops the frame AppKit keeps in the defaults (`NSWindow Frame terminal-AppWindow-1`), and the
   first window came back at the default size.

## Consequences

- A crash or a kill no longer decides what the next start shows; the session store does.
- Nothing of Sunset's is written to the saved state — shown the same evening, once the screen was unlocked: see below.

## Shown later the same day (t263)

With the screen unlocked, the same debug build twice, a session of two tabs (one a file, `notes.md`), a second window,
twenty seconds, then ended:

| Build | While running | After SIGTERM | After its own Quit |
|---|---|---|---|
| Points 1 and 2 taken out | `windows.plist` written: 2 titles, one of them the file's name | the same | (not tried) |
| As committed | nothing written | nothing written | nothing written |

So the record did hold window titles in plain (a file's name here), and no longer does. In the morning, with the screen
locked, neither build wrote anything: the system does not record windows then.

## Not shown, and what is left

- A record written by a build of before stays where it is: this build neither reads it nor removes it, and its own Quit
  does not either. The owner's was removed by hand on 2026-11-16 (it then held no window). Removing it from the app would
  mean reading the system's map of records, which is not ours to read.
- The app target has no suite; all of this was seen in the app, through the menus and pictures of its windows.

## Found on the way

Test copies share the owner's defaults (`studio.aemi.sunset`) and so his remembered window frame, and they shared this
record. They need a domain of their own (t276).
