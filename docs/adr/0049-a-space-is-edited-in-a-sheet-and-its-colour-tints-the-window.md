---
status: accepted
date: 2026-11-17
supersedes: the editor of 0047 (a popover that applied as it was typed); what closing the last tab does (left open there)
---

# 0049 — A Space is edited in a sheet of three fields; its colour tints the window; its last tab does not close the window

The owner, 2026-11-17, on what ADR-0047 built.

## Decision

| Subject | The owner's words | Built |
| --- | --- | --- |
| The editor | "more contained with 3 field, and a save and cancel"; "the picker should not be directly shown, we should just have 3 fields, one input for space name, 1 input with click to get the color picker but it would only tint the window and one field that would open the picker for the symbols or emoji" | A sheet: Name; Colour, a field that opens the colours; Icon, a field that opens the picker (ADR-0048). Cancel and Save |
| The last tab | "closing the last tab of a space should not close the window, but this could be a behaviour to decide about in a setting" | The window stays, on the empty Space; `tabs.closeWindowWithLastTab` (off by default) closes it as before |

Decided by the builder, to be said:

1. **Nothing is the Space's until Save**, and **a new Space is not made before**: Cancel leaves no Space behind. A Space
   needs a name: Save is off without one.
2. **A saved new Space is shown with the command bar open**: it has no tab (as a new window on a Space does).
3. **The colour is kept in the Space's look** (`look.tint`, `#RRGGBB`): the room R4 kept for it.
4. **How much it tints**: a third of the colour is mixed into the window's own tint (`appearance.tint.color`), at the
   tint's own strength: tinted, not painted, so that text still reads. With an opaque window material there is no tint
   to mix into, and the colour does not show.
5. **The symbol's own colour stays in the picker**: it is the icon's, not the Space's.
6. **A window that is not among the Spaces** (one tab a window, a private window) still closes with its last tab.

## Not decided here

- A tint for an opaque window, and for the sidebar's Spaces row (the icon is not coloured by the Space's colour).
- Whether an empty Space should open the command bar by itself when its last tab closes (it shows a line of text).
