---
status: accepted
date: 2026-11-16
---

# 0046 — The tabs left by the last window can be closed with it, or after a delay

ADR-0045: when the last window of a Space closes, its tabs stop and stay. The owner, in the same answer: "a setting
should allow to clean open tabs after a delay or when (last) window of a space closes". The names, the unit and the
defaults below are the builder's; they are his to change.

## Decision

1. **`tabs.closeWithLastWindow`** (off by default): on, the tabs of a Space close with its last window, as before
   Spaces. What is asked before a window closes (unsaved edits) is asked the same either way.
2. **`tabs.closeStoppedAfter`**, in hours (0 by default: never; at most 8,760): tabs that stayed, stopped, are closed
   once that long has passed with no window showing them. The time they were stopped is in the session (`stopped`, on
   the Space), so the delay counts across a quit: it is checked at launch, and by a timer while Sunset runs with no
   window. A window that shows them in time ends the wait.
3. Both are in Settings > General, with the other settings about tabs and quitting.
4. They are about the tabs of the Space only. Favorites are kept whatever they say; a private window's tabs always go
   with it; a window that is one tab (`tabs.mode` none, the system's tab bar) closes its tab as before.

## Not decided here

- A delay for each Space, once there are several: one setting for all for now.
- Cleaning tabs that were not stopped with a window but left unused (R4's sleep and unload after a while): another step.
