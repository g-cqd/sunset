---
status: in-progress (M-a done 2026-11-13, M-b done 2026-11-14, M-c done 2026-11-15)
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
| M-c | The pane: rendered natively, source, the toggle, Show Beside, Mermaid, text files, local images, links in a split. **Done 2026-11-15**, seen in the running app but for a click on a link (see below) | t165 |
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

## M-c as built (2026-11-15)

A new target, `SunsetMarkdown`: `DocumentContent` is the pane (kind `document`), a view of the app's one `OpenDocument` for
its file. Markdown and Mermaid open drawn by the kit's native view and toggle to their source (Cmd-Shift-E); any other text
is source only. Show Beside (Cmd-Option-E) opens the other view of the same document in a split: one text, so each follows
the other. Cmd-S saves; a failure is said in the pane and the edits stay. The tab shows the file's name, a document icon,
and a dot while there are edits (`PaneContent.isEdited`, new). Cmd-+ and Cmd-- size the text in both views.

Brought forward from M-f, as the owner agreed: **File > Open File (Cmd-O)**, each file chosen in a tab of its own.

- **Pictures** are read from local files only, relative to the document's folder (the kit, its ADR 0010): nothing is fetched.
- **Links** open beside the pane and never in it: a web address as a page (private in a private window), a file as a
  document, mail and folders by the system.
- **The page** is `DocumentPage`, one per document for every pane that shows it: made only while a pane has it on screen,
  at once for a text up to 32,768 UTF-16 units, off the main actor for a longer one. Typing in a long document no longer
  waits for its page (M-b's open point); the page then follows a moment behind, one page at a time.
- **A file that changed on disk under edits** is said in the pane with Reload from Disk and Keep Mine, until M-e merges.
- **Closing the last pane on an edited document** is confirmed like a running command, until M-d's sheet.

1,036 tests in 197 suites pass, on the pinned kit (AemiMarkdown 563e645, TerminalKit 791a6ca).

Seen in the running app the same day (the diary has each): the page, the toggle, typing and saving, the tab's dot, Show
Beside with the page following the source, a file changed on disk with and without edits, the text sizes, closing, a plain
text file. Two faults were found there and fixed: the app fell over when the page grew beside its source (the kit's
selection, AemiMarkdown 563e645), and quitting with a document in two panes lost its edits without asking (the quit sheet
now names each edited document once). Pictures: `docs/research/markdown/mc-screen-beside.png`, `mc-screen-notice.png`.

Not done, and where it goes:

- **A click on a link was not seen in the app** (accessibility cannot press a link among words, and a click sent to the
  process alone did not reach it): the kit has a test that clicks one in a window, Sunset a test of what is done with it.
  No file was opened through the Open panel either: it came up and was cancelled.
- `PaneContentKinds.make` and the menus are in the app target, which has no tests.
- The two views do not scroll together (M-g). A link to a place in the same page (`#part`) does nothing. SVG pictures and
  pictures among words are not drawn. A link to a file that is not text opens a pane that says so.
- No settings: the page uses the kit's defaults, and no `markdown.*` key exists.
- New documents with no file, the + menu, a drop, the command bar and the handler for .md are M-f; documents in the sidebar
  are 0030 ST-5.
- The page of a long document is still made whole each time (330 ms at 2 MB, off the main actor): rows by block is the
  kit's next step.

Not done: M-d to M-i.
