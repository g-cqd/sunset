---
status: in-progress (M-a done 2026-11-13, M-b done 2026-11-14)
blocked-by: 0018 (each step's own questions); 0019 (it comes after the web milestone, by the owner's order)
date: 2026-11-11
---

# 0023 — Markdown, and the document behind a pane

Decided with the owner in refinement session R6 (`docs/refinement/R6-markdown.md`, accepted 2026-11-11), which is the description to build from.
Nothing is built. Order of building given by the owner: folders (0020), the web milestone (0019), Markdown, Spaces and profiles (0021), web
beyond (0022). Each step starts with its own questions.

| Step | What | Task |
| --- | --- | --- |
| M-a | In AemiMarkdown: the editor, atomic saving and commands into `MarkdownLookKit` (proposed there). **Done 2026-11-13**, AemiMarkdown 26128d4 (its ADR 0008): the kit is a product of its root package; `MarkdownSource` (one text, one undo history), `MarkdownSourceEditor`, `AtomicFile`, `MarkdownCommand`; 123 kit tests. Not seen: the editor on screen | t115 |
| M-b | The document behind a pane, app-wide by file; the note kind removed. **Done 2026-11-14** (see below) | t164 |
| M-c | The pane: rendered natively, source, the toggle, Show Beside, Mermaid, text files, local images, links in a split | t165 |
| M-d | Saving: Cmd-S, the two settings, the sheet on closing, quitting | t166 |
| M-e | Changes on disk: reload, merge by nodes, conflicts asked | t167 |
| M-f | Opening: Open File, the + menu, a drop, the command bar, the handler for .md | t168 |
| M-g | The editor's tools: find and replace, formatting keys, the outline, smooth scroll sync | t169 |
| M-h | Paths in terminal output and Cmd-click on them | t170 |
| M-i | The command from the shell | t171 |

Apart, each its own refinement: Sunset's own document store and its library, with the widened encryption study (t172, t135); session R11,
commands, App Intents and the command bar (t173).

## The owner's answers at M-b and M-c (2026-11-13)

| Question | Answer |
| --- | --- |
| Does Markdown wait for Sunset's own store | **Yes**: the store's refinement (t172, with the studies t135 and t217) is held first, then M-b |
| A size limit for a text file as source | None |
| Where documents live in the code | Two targets: `SunsetDocuments` (one document per file for the whole app: its text, saving, watching the file) and `SunsetMarkdown` (the pane and its views) |
| What the tab shows | The file's name, a dot when it has unsaved edits, a document icon |
| Keys | Cmd-Shift-E toggles source and rendered; Cmd-Option-E is Show Beside; Cmd-S saves |

## M-b as built (2026-11-14)

`SunsetDocuments` now holds, besides the store (0030 ST-4): `OpenDocuments`, one for the app, which gives the same `OpenDocument` for a place
however it is asked for (`DocumentPlace`: a file by its real path, or a stored document by its id); the document's text is the kit's
`MarkdownSource` (one storage, one undo history), read as Markdown, as a Mermaid diagram or as plain text by the file's extension. It saves
(a file through the kit's atomic write, a stored document through the store), and it watches its file: unedited, a change is taken; edited,
it is only said (`changedOnDisk`); deleted, it is `missing`; what it wrote itself is not a change. The note kind is removed; a saved note is
kept as an unknown pane. Sunset pins AemiMarkdown 35b065d and TerminalKit 53e06bf.

Costs (release, medians, ours; diary 2026-11-14), after the kit's change that the first measure asked for (AemiMarkdown ADR 0009):

| | 20 KB | 200 KB | 2 MB | 10 MB |
| --- | --- | --- | --- | --- |
| Opening | 7 ms | 2 ms | 20 ms | 98 ms |
| A character typed, no page shown | 0.04 ms | 0.4 ms | 3.6 ms | 18 ms |
| A character typed, the page read after each | 3.5 ms | 33 ms | 327 ms | 1,640 ms |
| Memory held | 1.0 MB | 1.4 MB | 13.5 MB | 68 MB |
| Saving | 5 ms | 7 ms | 19 ms | 70 ms |

Not done in M-b, and where it goes: no pane and nothing on screen, and nothing in the app makes an `OpenDocuments` yet (M-c); the page
made again whole at each key when it is shown, which misses frames from about 100 KB (M-c must not make it at each key; rows by block
is the kit's next step); opening reads and parses on the main actor (98 ms at 10 MB; only the read after a change on disk is off it); an edited document is not merged with a change on disk (M-e); closing an edited document asks nothing (M-d); a file that is
not UTF-8 is `notText` and not shown.

Not done: M-c to M-i.
