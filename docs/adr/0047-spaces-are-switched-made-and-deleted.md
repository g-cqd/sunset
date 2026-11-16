---
status: accepted
date: 2026-11-17
---

# 0047 — Spaces: switching, making, moving a tab, deleting

Roadmap 0021, steps S-b and S-c, built together. R4 said where the Spaces show (a row of icons at the bottom of the
sidebar, the command bar, a menu, a button in the tab bar when there is no sidebar) and that nothing shows while there
is one. The owner answered the rest on 2026-11-17; his answers are the decision.

## Decision

| Question | The owner's answer |
| --- | --- |
| The keys | **Option-Command-1…9** for the nth Space, **Option-Command-Left/Right** for the one before and after. Fixed until there is a section for keys |
| The swipe | Two fingers on the sidebar, told from scrolling by the direction it starts in; the list follows the fingers: "it should snap to the space, starting slow and snap when enough swiped, not swipe multiple ones at the same time, please provide haptic feedback relevantly but we might want to bring haptic feedback with a more global and cohesive way later" |
| A Space left by switching | **Keeps running**: "all window should keep running for what is scheduled, unless app quits completely". Asked again about a Space whose last window is closed: that one still stops and stays (ADR-0045) |
| A new Space | Starts with **a copy of the Favorites** of the Space it was made from (kept, none open), and no tab |
| The first Space's name | **Home**, with a house, when a second is made; a new one is "Space N" with a numbered circle |
| Move to Space | The tab moves **running**, and **the window follows it** |

Decided by the builder, to be said:

1. **Which Space a window shows is the window's.** A new window shows the Space of the window it was asked from. Each
   window remembers what it had selected in a Space it left, and shows it again when it comes back.
2. **The swipe's numbers** (`SpaceSwipe`): the list moves at three tenths of the fingers' speed at first and catches up
   with them; at 30% of the sidebar's width it snaps, once; the rest of the gesture and the trackpad's momentum do nothing.
   Towards a side with no Space the list gives a little and never snaps: the swipe does not go round (the keys do).
   One tap of the trackpad at the snap (`NSHapticFeedbackManager`, `.alignment`), called where it happens: there is no
   haptics layer yet, as he said.
3. **Every Space stops when the app's last window closes**, the ones left by switching too: with no window anywhere
   nothing can show them (unless Sunset is kept running for an open Favorite, where they stop all the same).
4. **Deleting** a Space that holds a tab or anything in its Favorites asks: move what it holds to the neighbouring Space
   (tabs running, entries as they are), close everything in it, or cancel. An empty Space is deleted at once. The last
   Space cannot be deleted.
5. **The copy of the Favorites** has ids and panes of its own (a pane is in one place) and keeps names, icons, what each
   entry starts from, and commands with their seals.
6. **A window that is one tab** (`tabs.mode` none, the system's tab bar) shows the first Space only; the others keep what
   they hold, with no window, until the mode lists tabs again. A private window is not among the Spaces.
7. **The command bar** lists a Space by its name, and the tabs of the other Spaces that match, each marked with its
   Space's name; going to one changes Space.

## Not decided here

- What closing the last tab of a Space does when there are several: today the window closes, as it does with one Space.
- Reordering Spaces by dragging their icons (the menu has Move Left and Move Right), and dragging a tab onto an icon or
  to the sidebar's edge (R4).
- A look for each Space (R4: room is kept in the file), and a delay after which a Space no window shows is stopped.
