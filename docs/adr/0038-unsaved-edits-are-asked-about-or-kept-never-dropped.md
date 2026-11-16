---
status: accepted
date: 2026-11-16
---

# 0038 — Unsaved edits are asked about or kept, never dropped

## What asked for it

R6 (Markdown): "writes on Cmd-S, atomically, and optionally on a timer or on losing focus. Closing with unsaved edits asks
Save, Don't Save, Cancel"; "a pane with no file: kept by Sunset until saved". Roadmap 0023 step M-d. The owner was away and
said to go on with sensible defaults: every point below is one of those, and his to change.

## Decision

1. **A file changes when its owner says so.** `documents.saveAfter` (seconds, 0) and `documents.saveOnFocusLoss` (false)
   are both off by default. The time counts from the first unsaved edit, so it bounds what a crash can lose; a pause in
   typing is not waited for.
2. **A save nobody asked for is never a guess.** It does not write over a file that changed on disk under the edits (that
   choice is the person's, and M-e's), does not make a deleted file again, does not write a file that was not read. When it
   fails it says so in the pane, once, and tries again after the next edit.
3. **A document of Sunset's own store is kept without a setting**: two seconds after an edit, on losing focus, when its
   last pane closes, at quit. It has no other copy and no one to ask where to put it. It is asked about like a file only
   once keeping it has failed.
4. **Closing asks in a sheet**, Save / Don't Save / Cancel, for the documents whose every pane (in every window) is among
   the panes that close. The two-click red tab stays what it was: the confirmation of a running command, which comes first.
   A Save that fails closes nothing.
5. **Quitting asks about unsaved files at every level of `tabs.askBeforeQuit`**, `never` included: that setting is about
   interrupting work, and was written before a pane could hold something that exists nowhere else.
6. **The window asks too.** SwiftUI gives no say on a window closing, so `WindowCloseGuard` stands in front of its window
   delegate and answers `windowShouldClose`, passing everything else on.
7. **What gets past all of that is kept.** `OpenDocuments` forgets a document with its last pane only when it has no
   edits or they were given up (Don't Save); otherwise it stays, held by no pane, shown again when its file is opened and
   named when quitting.

## Why

- Losing text is the one fault a person does not forgive an editor; a question too many is forgiven. Point 7 exists
  because points 4 to 6 are a list of doors, and a list of doors is never complete (a window closed by code, a pane closed
  by its program, a path added next month).
- Autosave off by default: a terminal's documents are mostly files under version control or watched by a build; writing
  them while they are half typed starts builds, reloads servers and dirties a work tree nobody asked to touch.
- The stored document is the opposite case: nothing watches it, and "Untitled" with a question at every close is what the
  owner's store was made to avoid.

## Considered

- **`NSDocument`**: it has all of this, and its own windows, tabs and autosave store; the pane model (one document in two
  panes, in two windows) does not fit in it.
- **Swizzling `performClose`** or observing `willClose` and reopening: the first is fragile, the second is too late.
- **Autosave on by default, like the system's**: see above; and the system's has Versions behind it to undo with.

## Consequences

- `tabs.askBeforeQuit = never` no longer means that quitting never asks; the setting's note says so.
- A pane's `closeWarning` is about running programs only; `PaneContent.unsaved` is the new requirement, nil by default.
- If SwiftUI replaces the window's delegate the guard is lost; point 7 then holds the edits.
