---
status: accepted
date: 2026-11-17
---

# 0064 — The sidebar's field is always there, a tab's size, and the command bar opens in it

The owner, 2026-11-17 (roadmap 0035 G): "Address bar in the sidebar should always be there and be used as a central place
where to start a search or creating a tab when focused on a terminal tab. its dimensions should match ones of a regular
tab". His answer: the command bar's results are listed under it.

## Decision

1. **Always there**, docked or floating: the focused page's address where pages have it in the sidebar (`web.address`
   sidebar), else a field that says "Search or Enter Address" ("Go to a Tab" with the web off).
2. **A tab's size**: as tall as a tab's row (`Design.oneLineHeight`, 32 pt by default; it was 26), the rows' side inset,
   a tab's corner and leading padding; the rows start a row's gap below it. A field inside a container that sets a height
   (`controlHeight`) now takes it when it gives none itself.
3. **The command bar opens in it** (a click on it, and Cmd-L while the sidebar shows it): its field in the field's place
   and size, its rows (tabs, an address or a search, suggestions, documents, actions) under it in the sidebar's width,
   the window dimmed as before. Return on an address or a search with a terminal shown opens it in a new tab, as the
   command bar did. Without the sidebar it opens over the panes, as before.

## Seen

With a terminal shown: the field at a row's height and width; clicked, the command bar in its place; "m" typed: a search
row; Return: a new web tab, its address in the same field.

## Not done

- In the sidebar's width a row's title is cut in the middle when it is long ("Searc…for").
