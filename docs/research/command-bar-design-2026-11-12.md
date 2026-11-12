---
status: for the owner's reading
date: 2026-11-12
asked-in: web step c (R1), the owner's answer "all of it now, after a study of Spotlight, Raycast and Sol I show you first"
---

# The command bar: what Spotlight, Raycast and Sol do, and what Sunset could take

## Sources, and what was not checked

- Raycast: its manual (manual.raycast.com: Search Bar, Action Panel, Keyboard Shortcuts), read on 2026-11-12.
- Sol: its README (github.com/ospfranco/sol). It says little about its look; what follows of Sol is from its public screenshots as I remember
  them. **Not checked.**
- Spotlight (macOS 26 and 27): Apple's help page gave no readable text to the fetch; what follows is from memory of macOS 26's Spotlight. **Not
  checked on this machine**: opening Spotlight would mean typing into the system's UI, which I do not do.
- None of the three is installed here; nothing was looked at running.

## What each does

| | Spotlight (macOS 26) | Raycast | Sol |
| --- | --- | --- | --- |
| The panel | One glass field; results appear under it when typing; it grows with them | One field on top; the list below; a bar at the bottom with the primary action and its key, and "Actions ⌘K" | One field, a list below, a small footer |
| Grouping | Sections by kind (top hit, apps, files, actions…) | Sections with small headers ("Favorites", "Suggestions", "Commands") | Flat with some sections |
| Modes | Browse views by kind (apps, files, actions, clipboard) by a key or a click on icons by the field | A command opens its own view inside the window; Esc goes back | Same idea, fewer views |
| A row | Icon, title, subtitle; the selected row filled | Icon, title, subtitle, on the right an accessory (kind, a key, a count); the selected row filled, hover a lighter fill | Icon, title, right-hand hint |
| Doing more with a row | Actions with fields filled in Spotlight itself (App Intents' parameters) | Return = primary action; ⌘K opens the Action Panel: every action of the selected row, searchable, each with its key; ⌘Return secondary, ⌥Return tertiary; sub-menus and small forms inside the panel | Few: Return; some with modifiers |
| Shortcuts in a row | Quick keys: a short word typed runs an action | Aliases and hotkeys set from the Action Panel | Custom shortcuts |
| Moving | Arrows | Arrows, ⌃N/⌃P, ⌘↑/⌘↓ between sections, ⌥↑/⌥↓ by pages; ↑ at the top recalls earlier searches | Arrows |
| Learning | Ranks by use | Frecency (often and recent), with "Reset Ranking" per item | Frecency |

## What Sunset's bar is today

A glass panel 520 pt wide with a field and a flat list of tabs (glyph, title, directory, pane count); the selected row filled; no hover or pressed
state, no sections, no footer, no actions besides Return; since step b a "Go to" row.

## Propositions for this step (to choose from; nothing is built)

1. **States on every row**: hover a light fill, pressed a darker one, selected (keyboard) the accent's fill with white text, as Raycast and macOS
   menus do; the pointer moving over rows does not move the keyboard selection until it moves (no jump under a still pointer as the list changes).
2. **Sections with headers**: Tabs, Go to, Search, Suggestions (and later Commands, History, Favorites); ⌘↑/⌘↓ jump between sections.
3. **A footer** like Raycast's: on the left what the bar is doing ("Go to a tab", "Split with…"), on the right the primary action of the selected
   row with its key ("Show Tab ↵") and "Actions ⌘K".
4. **Each row's actions (⌘K)**: a small panel over the list, searchable, each action with its key. For a tab: Show, Close, Split Right, Split
   Down, Move to New Window, Rename, Keep in Favorites. For a page row: Open Here, Open in New Tab, Split Right, Copy Address. For a search: Search
   in a new tab. ⌘Return the second action (for a tab: Split Right; for an address: open in a new tab), ⌥Return the third.
5. **The engine as a chip in the field**: typing an engine's keyword and a space ("ddg ") turns it into a chip at the start of the field (Raycast's
   way with a command's argument); Backspace on an empty field removes it.
6. **An accessory on the right of a row**: the kind ("Tab", "Page", "Search"), the pane count, or a key for tabs 1–9 (⌘1…).
7. **Recall**: ↑ in an empty field brings back earlier entries (kept for the session only until the history of step e).
8. **The panel's size**: 640 pt wide (from 520) so suggestions and addresses fit; at most 9 rows shown, then scrolling.

Left for later (C-3, t188, or never): modes with their own views, forms inside the bar, aliases and hotkeys set from it, ranking that learns.

## What each costs

- 1–3, 6, 8: views only; no speed or memory cost worth naming.
- 4: the largest piece (a second panel with its own focus and search); all of the actions exist already in the menus.
- 5: small, but it changes what the field holds (a chip and text).
- 7: a list of strings per window; nothing saved.
