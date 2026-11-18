---
status: accepted
date: 2026-11-18
supersedes: R4's "pages sleep after 15 minutes" (the setting and its moon cue)
---

# 0071 — Hidden pages are unloaded after a delay and under memory pressure; their sleep is WebKit's

## Context

R4 asked for three settings (sleep after 15 minutes, unload after 12 hours, unload the longest idle under memory
pressure), exceptions, keep awake, and a cue; and the study t134 first. The study (docs/research/
webkit-sleeping-pages-2026-11-18.md) found that a page out of its window has its timers slowed to about once a second at
once, whatever `inactiveSchedulingPolicy` says. Decided by the builder while the owner was away (2026-11-18: "don't ask
me anything"); each point is his to change.

## Decision

1. **No sleep setting.** A hidden page sleeps as WebKit makes it, at once. No moon cue.
2. **`web.unloadAfter`**: hours, 12 by default, 0 never (0–168). A page hidden that long lets go of its view; its
   address, history and place (`interactionState`), title and picture stay; shown again it is made again there.
3. **`web.unloadUnderPressure`**, on by default: while macOS's pressure level is warning or critical, the page hidden the
   longest is unloaded, one a minute (`kern.memorystatus_vm_pressure_level`, polled; no dispatch).
4. **Never unloaded**: a page on screen; one that plays sound, captures, or waits on a dialog or a sign-in question; one
   kept awake (the tab's Keep Mac Awake); one in a Pinned grid ("pinned" read as the grid, not the Favorites); one
   holding text typed and not sent, as far as its fields show (`value` differs from `defaultValue`, or a filled
   content-editable element): not perfect, said here as R4 says it.
5. **The cue**: an unloaded page's icon is dimmed (`PaneContent.isUnloaded`), in the list and wherever its icon is.
6. Settings > Web > Memory holds both.

## Not done

- A terminal that is not running is not dimmed (R4 asked the same dimming).
- "Driven by an agent or a terminal" is not an exception yet: nothing drives a page yet (remote control, roadmap 0027).
- `sessionStorage` is not kept across an unload (`fetchData`/`restoreData`, macOS 26): a page that keeps its state there
  starts without it.
- Not measured: the memory an unload frees, and a page's time to come back.
