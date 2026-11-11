# R6 — Markdown, and the document behind a pane (roadmap 0018)

Status: **accepted by the owner 2026-11-11** (roadmap 0023, tasks t115, t164-t174). Nothing here is built.
Input: note n43, task t115, R2 (the hidden note pane; one document in two panes), `AemiMarkdown/Apps/MarkdownLook` (its README read today).

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| What the pane is | A viewer and a source editor | Editing the rendered document is a future feature of MarkdownLook's own lane, not required in Sunset now |
| Source and rendered | A toggle in the pane, and a split when asked: the second pane shows the other view and follows | |
| The document | App-wide, by file: every pane on a file is one text, one undo history, one edited state | |
| Saving | Cmd-S, plus two settings (a timer; on losing focus) | Storage in the app or on the computer, chosen by the user, in the app by default; could benefit the encryption study |
| The in-app storage | A store of Sunset's own | This needs to be refined |
| An in-app document whose pane is closed | It stays in a library, to reopen or delete | |
| Encryption | One study for the web store and in-app documents (t135, widened) | |
| A change on disk | Reloaded silently if unedited; merged if edited | Ask when nodes conflict |
| A pane with no file | Yes, kept by Sunset until saved | |
| Opening | Open File and the + menu; dropping a file; Cmd-click on a path in a terminal; a command from the shell; the command bar; as the Mac's handler for .md | Build with App Intents in mind: the system and the command bar can run actions such as a new tab of any kind |
| Which files | Markdown, Mermaid, and any text file as source | |
| What draws it | The kit's native view | |
| Images | Local files only | |
| Links | Everything in a new split | |
| The editor | Find and replace; formatting keys; an outline to jump by heading; scroll kept in step between source and rendered | The scroll sync animated and smooth |
| The kit | The editor, atomic saving and commands move into `MarkdownLookKit`, proposed in AemiMarkdown and accepted there, when Markdown's turn comes | |
| Unsaved edits on closing | Ask: Save, Don't Save, Cancel | |
| Commands and App Intents | Every action declared once and run by menus, keys, the command bar, App Intents and later remote control: yes, as its own refinement topic | |
| The command bar running actions | Yes, with no prefix | Word matches, indexing, ranking, tolerant of errors, perhaps semantic search |
| Order | Folders, the web milestone, Markdown, Spaces, profiles, web beyond | |

## The outcome, as one description

A **document** is a thing of its own behind the panes that show it: one per file for the whole app, with one text, one undo history and one
edited state, so two panes can never hold two unsaved versions. The Markdown kind shows a document either rendered, drawn natively by
`MarkdownLookKit` with no web engine and nothing in it running, or as source with colouring; a key toggles, and Show Beside splits so that source
and rendered sit in two of Sunset's own panes, scrolling in step, smoothly. Mermaid files render; any other text file opens as source only. Images
load from local files only. A link opens in a new split.

The editor has find and replace, formatting keys and an outline by heading. It writes on Cmd-S, atomically, and optionally on a timer or on
losing focus. Closing with unsaved edits asks Save, Don't Save, Cancel. When the file changes on disk, an unedited document reloads silently; an
edited one is merged by Markdown nodes, and conflicting nodes are asked about.

A document need not be a file: by default a new one lives in **Sunset's own store**, where it stays in a library after its pane closes, and it
can be moved to a file. The store's form is not decided: it gets its own refinement, with the encryption study (t135, now covering the web store
and these documents).

Documents open from Open File, the + menu, a drop, the command bar, Finder (Sunset as a handler for .md), a Cmd-click on a path in a terminal,
and a command typed in a shell.

It replaces the hidden note pane, which is removed then.

Two things came out of this session that are larger than Markdown and get **their own refinement session (R11)**: a command model, where every
action is declared once and run by the menus, the keys, the command bar, App Intents and later remote control; and the command bar as the place
to run them, with no prefix, matching by words, ranked and tolerant of errors.

Costs, as the owner asked to see them. **Memory**: one copy of a document's text however many panes show it; the native view needs no web
process; a text file as source is held whole in memory, so a size limit is asked at that step. **Speed**: the rendered side re-renders as you
type; what that costs on a long document is to be measured (the kit has benchmarks). **Safety**: atomic writes; one edited state per file; a
merge is the risky part, since a wrong merge is silent damage: only non-conflicting nodes merge by themselves, the result stays undoable, and
conflicts are shown. A store of our own can lose every document with one damaged file: integrity checks and a backup are part of its refinement.
**Security**: nothing in a document runs and no image is fetched from the network; a command from the shell that opens a file gives any program
in a terminal that ability, to be bounded at that step; an App Intent can be run by a Shortcut the person did not write, a question for R11.

## Said plainly

- Cmd-click on a path needs paths to be found in terminal output: not built today (only OSC 8 links are). It is a step of its own.
- The command from the shell needs a channel into the app (remote control, not built, or an escape sequence): decided at that step.
- Until the store exists, a new document can only be a file with a name asked first; whether Markdown waits for the store is asked at step M-b.
- "Any text file as source" makes Sunset a text editor in a small way. No colouring per language is promised.
- `MarkdownLook`'s README says its macOS 26 runtime was not tried; the kit's native view on macOS 26 is unverified.

## Steps (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| M-a | In AemiMarkdown: the editor, atomic saving and commands into `MarkdownLookKit` (proposed there) | What the kit's public surface is |
| M-b | The document behind a pane, app-wide by file; the note kind removed | Where documents live in the code; a size limit; does Markdown wait for the store |
| M-c | The pane: rendered natively, source, the toggle, Show Beside, Mermaid, text files, local images, links in a split | Keys; what the tab shows (name, edited mark) |
| M-d | Saving: Cmd-S, the two settings, the sheet on closing, quitting | |
| M-e | Changes on disk: reload, merge by nodes, conflicts asked | How a conflict is shown (sketches) |
| M-f | Opening: Open File, the + menu, a drop, the command bar, the handler for .md | |
| M-g | The editor's tools: find and replace, formatting keys, the outline, smooth scroll sync | Which keys |
| M-h | Paths in terminal output and Cmd-click on them | Which paths; relative to what |
| M-i | The command from the shell | The channel; its bounds |
| Store | Sunset's own document store and its library: its own refinement, with the widened study t135 | |
| R11 | Commands, App Intents and the command bar: its own refinement session | |
