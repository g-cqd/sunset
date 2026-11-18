---
status: in-progress
blocked-by: nothing
date: 2026-11-17
---

# 0041 — Help and tooltips across the app

The owner, 2026-11-17: "investigate how to bring this helper logic to sunset so that we can display tooltip and help across
the whole app". His answers: a Help section in Settings, and a separate window that reuses the shell; a "?" beside titles
or settings where space is not constrained; in order: the sidebar's controls, then the settings, then the web's
permissions. The study: docs/research/help-system-from-vmrunner-2026-11-17.md.

| Step | What | Blocked by | Status |
| --- | --- | --- | --- |
| A | Topics and their texts (`HelpTopic`, `HelpCatalog`: a one-sentence summary that is the tooltip, plain text, an expert part, related topics), the `.helpTopic(_:)` modifier, the "?" with its popover, and the gates (every topic has text; summaries short sentences; related topics exist; no `.help("…")` literal outside a short list) | — | done: `SunsetHelp`, `HelpCatalogTests` (in SunsetShellTests), `HelpLiteralTests` (the list frozen at today's 23 less the 3 moved) |
| B | The sidebar's controls: rows, Pinned, Favorites, folders, the field, the bottom bar, the Library's rail, the cup, drag and drop | A | done: eleven topics; the field's and the cup's tooltips are theirs. No "?" in the sidebar (no room) |
| C | The settings: each option's note from its topic, a "?" beside each where there is room | A, 0040 | done but notes from topics: a "?" beside the five settings a sidebar topic explains (seen); 2026-11-18 the settings' own topics for what their notes could not hold: Spaces (two settings), features, appearing as another browser (two), in a new General area. The note under a setting stays its own sentence (a topic's summary is a tooltip, not the same text) |
| D | The web's permissions and policies (white paper §9): each permission, notifications, downloads, pop-ups, profiles, private windows | A | done: eight topics (what sites may do, notifications, pop-ups, dialogs, downloads, profiles, private browsing, plain http), each checked against the code; a "?" beside the six settings they explain |
| E | A Help section in Settings (the Library's), searchable as Settings are; and a Help window reusing the shell (its sidebar of topics, the topic on the right); the Help menu opens it | A | done: Help > Sunset Help opens a window with a Help tab (topics by area and a search on its left, the topic on its right); a Help row at the foot of Settings' list. Seen. ⌘? is the system's (the Help menu's search): no key of ours |

## Not done

Settings' topics beyond sixteen settings (only those whose note lost detail have one). "Open in Help" from a popover. The Help tab joins the Space the window shows (a window is a view
of a Space), so it is listed in that Space's other windows too.
