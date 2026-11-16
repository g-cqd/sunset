---
status: in-progress (M-a done 2026-11-13, M-b done 2026-11-14, M-c done 2026-11-15, M-d done 2026-11-16, M-f done 2026-11-16; M-e waits for the owner)
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
| M-d | Saving: Cmd-S, the two settings, the sheet on closing, quitting. **Done 2026-11-16** (see below, ADR-0038) | t166 |
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
- **Closing the last pane on an edited document** was confirmed like a running command; M-d's sheet replaced that.

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

## M-d as built (2026-11-16)

Decided without the owner, who was away and said to go on with sensible defaults; the decisions and their reasons are
ADR-0038, and each is his to change.

- **Two settings, both off**: `documents.saveAfter` (seconds; a file is written that long after its first unsaved edit) and
  `documents.saveOnFocusLoss` (when another pane takes the keyboard, or another app comes to the front). Settings > General >
  Documents. A file is never written by itself over a change made on disk under the edits, never made again once deleted,
  never written when it was not read; a save that fails by itself is said in the pane and tried again after the next edit.
- **A document with no file is kept by Sunset**: two seconds after an edit, when it loses focus, when its last pane closes,
  at quit. It is asked about only when keeping it has failed.
- **Closing asks Save, Don't Save, Cancel**, in a sheet on the window, whatever closes: a pane, a tab, the other tabs, a
  kept entry unloaded or deleted, a folder, the window (its red button, Close Window). Only for a document whose every pane
  is going: one pane of two closes without a word, a tab that holds both asks once (before, that lost the edits silently).
  A running command is confirmed first, as before. A Save that fails closes nothing and shows the pane, which says why.
- **Quitting asks about unsaved files whatever `tabs.askBeforeQuit` says**, with Save All and Quit as the answer of Return.
- **Edits are never forgotten without a word**: a pane closed by a way that did not ask leaves its document open, held by
  no pane, until it is saved or given up; opening the file shows the edits again, and quitting names them.

1,185 tests in 225 suites pass. Seen in a test copy of the app (diary 2026-11-16-01): the sheet on Cmd-W, on Close Window
and on the red button pressed through accessibility; Save, Don't Save and Cancel; a Save that fails; the quit sheet with
`askBeforeQuit` at never; a file written 1 s after an edit, and on switching tab; a new document kept without a question;
the settings page. Pictures: `docs/research/markdown/md-unsaved-sheet.png`, `md-quit-sheet.png`.

Not done, and where it goes:

- **Not seen**: a real click on the red button, the keys of the sheet (Return, Escape, Cmd-D), saving when another app
  comes to the front (a test copy is never the front app; the model's side has a test), the alert when quitting with no
  window left, a window closed by the system.
- The app target has no tests: `QuitGate`, `WindowCloseGuard` and the sheets are covered by what was seen, not by a suite.
- `WindowCloseGuard` stands in front of SwiftUI's window delegate; if SwiftUI ever puts its own back the window closes
  without asking, and the edits are then kept and named at quit rather than lost.
- No Save As, and no Revert; a stored document cannot be given a file yet (M-f). Changes on disk are still M-e.

## M-f as built (2026-11-16)

Decided without the owner (ADR-0040); each point is his to change. Done before M-e, which needs his answer on how a
conflict is shown.

- **Open With, and a drop on the icon**: Sunset declares Markdown, Mermaid and plain text, as an editor that is never the
  default (rank Alternate). Each file opens in a tab of the window that acts; one that window already shows is shown. A
  Sunset started on a file opens one window, with the session's tabs first when there is a session.
- **A drop on the window**: on a terminal pane the paths are typed there as a paste, quoted for the shell, and the pane
  takes the keyboard; nothing is run. A name that holds a control character is never typed. On any other pane each file
  opens as a document; folders do nothing there.
- **The + menu** has New Document and Open File….
- **The command bar**: a typed path (`/…`, `~/…`, `file://…`) to a file that is there gives "Open name" as the first row;
  stored documents whose title holds the words typed are listed, except those already in a tab.

Found on the way and fixed on its own (ADR-0039): Sunset started with no window when the system's saved state said so.

1,196 tests in 229 suites pass. Seen in a test copy: a cold start on a file, with and without a session; files sent to
a running copy, one of them a link to a file already shown; the bar's Open row and Return on it
(`docs/research/markdown/md-bar-file-row.png`).

Not done, and where it goes:

- **Not seen**: a drop of any kind (none can be made in the background; `FileDropTests` covers what is typed), the + menu's
  two items, the stored documents' rows in the bar, Finder's Open With on the installed build.
- The app target has no tests: `PaneDropDelegate`, `DocumentRows` and `AppDelegate.application(_:open:)` are covered by
  what was seen.
- A debug build beside the installed one declares the same types under the same bundle identifier: which of the two the
  Finder starts is the system's choice. Test copies need an identifier of their own (t276).
- No Save As; a stored document cannot be given a file yet. Relative paths and `file:line` in the bar are not read. A
  dropped folder opens nothing.

## The owner's answers on his return (2026-11-16)

| Question | Answer |
| --- | --- |
| The decisions of M-d and M-f taken in his absence | Kept, but one: **a file saves itself by default**, 2 s after an edit and on losing focus (ADR-0041; done the same day) |
| M-e: how a conflict is shown | **On the block, in the document**: both versions tinted in place, Keep Mine, Keep Disk's, Keep Both on the block, a count with previous and next at the top; in both views |
| M-e: while a conflict is unanswered | **Save is refused**: Cmd-S shows the first conflict; a save by itself waits |
| M-e: blocks merged by themselves | **They flash** (a brief tint on each), with a notice that has Undo; the merge is one undo step |
| A document dragged from the Library when a tab shows it | A second tab (as built); opening a file selects the tab that shows it |
| Test copies | Debug builds become `studio.aemi.sunset.dev` (t276) |
| After M-e | The test identity, the Library leftovers (t279), t263; then Spaces, profiles and the Pinned grid; then acting as Chrome on some sites (t280) |

Not done: M-e, M-g to M-i.
