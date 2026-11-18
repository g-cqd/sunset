# Folds, menus and what they show

The owner's note n45 (2026-11-18): one rule for what opens more, and the same symbols for it everywhere.

| What it does | How it looks | Its symbol |
|---|---|---|
| Shows more in place, under it (a fold: settings' More, a site's permissions, a search engine, Help's "For experienced users", a folder of the sidebar) | A `DisclosureGroup`, or the sidebar's folder row | The system's chevron, on the leading edge: right when folded, down when open. The label is text only: no symbol of its own after the chevron |
| Opens a menu from a button with a glyph (Documents' order, the find bar's options) | The button's own glyph | None: no menu indicator beside the glyph |
| Opens a menu or a list from a field-like control (the Space editor's fields, a picker) | The control's text | The system's ⌃⌄ (`chevron.up.chevron.down`) on its trailing edge |
| Opens a window, a sheet or a panel | Its title | "…" at the end of its title, no symbol |
| Moves between things (back, forward, previous, next) | Its glyph | `chevron.left`/`right` (pages), `chevron.up`/`down` (matches, conflicts): never a fold's |

In a popover, a fold or a group, the content takes the whole width: a switch on the trailing edge, its text on the leading
edge (`settingSwitch()`), as a settings row.
