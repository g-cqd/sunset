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
- Nothing of Sunset's is to be found in the saved state — **intended, not yet shown**: see below.

## Not shown

- That nothing is written. With the screen locked (it was, for the whole probe) neither the build before the change nor the
  one after wrote a record in fifteen seconds with two windows, nor at a kill: the probe does not tell them apart. t263
  stays open for it.
- The app target has no suite; all of this was seen in the app, through the menus and pictures of its windows.

## Found on the way

Test copies share the owner's defaults (`studio.aemi.sunset`) and so his remembered window frame, and they shared this
record. They need a domain of their own (a task).
