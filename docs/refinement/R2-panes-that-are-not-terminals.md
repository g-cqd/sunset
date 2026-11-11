# R2 — Panes that are not terminals, as built (roadmap 0018)

Status: **answered except one point (where the + button is), 2026-11-11.** To be read back and accepted.

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| The note pane | Hidden now, replaced by the Markdown pane later (R6) | Done in d01b61e: no menu item makes one |
| A kind this build cannot make | A placeholder tab, kept and written back as it was (as built) | |
| How a pane of a kind is asked for | A menu item per kind | And a + button that opens a menu, near the panes: in the sidebar, or in the toolbar when there is no sidebar |
| A click on + | Always opens the menu | |
| A split with a pane that is not a terminal focused | The same kind by default, configurable | |
| What a page's split shows | A setting; default: empty, with the address focused | The address focused could be the Cmd-L input in that context |
| The hover preview | A snapshot for every kind | A split tab's preview shows its split configuration |
| How a split tab's preview is made | A miniature of the layout, drawn on demand: nothing is kept | |
| Cmd-plus / minus / 0 | Act on the focused pane; with a terminal focused, all the window's terminals change as today | |
| One document in two panes | Needed for the kinds that are edited | To be designed before the Markdown pane (R6) |
| Budgets for the web steps | Measured and reported at each step, not gated | |
| The terminal performance work | Stays deferred | |
| The costs not spelled out in R1 (no sleep, suggestions sent to Google, inspector on, http for local names, a plain store, history on disk, a picture per tab) | Not answered: they stand as accepted unless the owner says otherwise | |

## Open

- Where the + button is: sketches A to D in `sketches/R2-plus-button.svg` (`.png` beside it).

## What follows from it (no task until accepted)

1. The + button and its menu of kinds (terminal now; page with web step a), where the owner places it.
2. Split of the same kind, with its setting (same kind / terminal), and for a page the setting of what it shows; comes with web step a.
3. The preview for every kind, and a split tab's miniature drawn on demand: each kind gives a picture of itself when asked.
4. Cmd-plus / minus / 0 go to the focused pane: a page's zoom is web step d.
5. A document behind a pane, for edited kinds: its design is a question of R6.
