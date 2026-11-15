---
status: accepted
date: 2026-11-15
---

# 0036 — The window's buttons stay in AppKit's title bar and are put back whenever they move

Supersedes one decision of roadmap 0017 (its S2 and design note "reparent them into a container we place") as ADR-0034
recorded it built. The rest of ADR-0034 stands.

## What changed the decision

The owner, 2026-11-15: the traffic lights "start in the wrong place". Probed (`docs/research/traffic-lights-search-2026-11-15.md`,
`Scripts/lights-probe`): with a new window, and always while the screen is recorded, AppKit took the three buttons back into
its title bar at (9, 9) within 100 ms of the window showing, and nothing in Sunset noticed. With the sidebar on the right
they sat at the top left, over the terminal, until a resize.

## Decision

- **The buttons are not taken out of the title bar.** They are AppKit's; they are moved within their own bar. The bar's
  container is made taller when the place asked for is lower than it is tall, never shorter than AppKit made it.
- **Every move is noticed.** The frames of the three buttons, of their bar and of its container are observed, with the
  window's notifications (resized, live resize ended, key, main, left full screen, changed screen); on any of them the
  buttons are put back when they are not where they should be. Observed anew when AppKit has made its title bar again.
- **The spacing between them is AppKit's, read once.** Full screen is left to macOS.
- It is one class with no knowledge of Sunset's configuration, `WindowLights` in `SunsetShell`, so that it is tested with a
  real window; `ChromeView` says where the buttons go.

The way of the Search browser (Office Commun, MIT), read for this and credited in the code; none of its code is used.

## Evidence

- `WindowLightsTests` (6): from the left and mirrored from the right; the buttons keep their parent; a resize leaves them in
  place; a button moved by anything is put back, and nothing is moved when nothing was; hidden they are parked and faded,
  through an AppKit layout too; with no placement AppKit's layout is left alone.
- `Scripts/lights-probe/run.sh` before and after, five configurations (the table in the research note): wrong in three of
  five before, right in all after.
- The first frames of a starting window, recorded: the buttons in place in every frame.
- The close button pressed through accessibility closes the window.

## Not established

- The pointer over the buttons (the symbols that appear), a click with a real pointer, Option-click on zoom: not made in
  the background.
- Full screen and back, the system's tab bar (`tabs.mode` native), a window dragged to another screen: not seen.
- Whether the taller container changes where a drag of the window starts, when the buttons are placed lower than the title
  bar is tall (the tab bar of capsules).
