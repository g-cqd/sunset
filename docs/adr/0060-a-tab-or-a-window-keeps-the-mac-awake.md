---
status: accepted
date: 2026-11-17
---

# 0060 — A tab or a window keeps the Mac awake, until it is closed or until its command ends

The owner, 2026-11-17 (roadmap 0035 E): "Add possibility to have a tab or a window keep the mac awake as long as it is
running". His answers: both ways, chosen; whether the display stays on too is "configurable".

## Decision

1. **A tab** (its menu, in the sidebar and in the built-in bar) and **a window** (Window > Keep Mac Awake) can be kept
   awake **until it is closed**, or **until its command ends** (a window: until none of its tabs runs one). The second is
   offered only while a command runs, and does not wait for the next one: it is forgotten once the command has ended.
2. A command runs when a terminal's shell has a program in front (`foregroundCommand`, already looked at after the screen
   changes): `PaneContent.runsCommand`, read without asking the system.
3. **A tab kept awake is the Space's** (`SpaceModel.awake`): every window on the Space sees it. A window's is its own
   (`TabsModel.windowAwake`).
4. **One system activity for the app** (`MacAwake`, `ProcessInfo.beginActivity` with `idleSystemSleepDisabled`), held
   while one window wants it, followed by observation. With **`tabs.keepAwakeDisplay`** (off by default) the display stays
   on too (`idleDisplaySleepDisabled`). Probed: `pmset -g assertions` lists `PreventUserIdleSystemSleep`, and with the
   display `PreventUserIdleDisplaySleep`, named "A tab or a window is kept awake".
5. A tab kept awake shows a cup after its title.

## Not done

- A kept entry (Pinned, Favorites) cannot be kept awake from its menu: only Today's tabs and windows.
- A Space whose last window closes stops its tabs (ADR-0045): what they kept awake lets go with them.
- Not seen on screen.
