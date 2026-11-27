---
status: accepted
date: 2026-11-16
supersedes: point 1 of 0038 (the defaults only)
---

# 0041 — A file saves itself by default: two seconds after an edit, and when it loses focus

## What changed

ADR-0038 added `documents.saveAfter` and `documents.saveOnFocusLoss` and left both off, reasoning that a file changes when
its owner says so. It was decided while the owner was away. Asked on his return (2026-11-16), he changed exactly this one:
**on focus loss, and 2 s after an edit**.

## Decision

- `documents.saveAfter` is 2 by default; `documents.saveOnFocusLoss` is true by default. A file then behaves as a document
  of Sunset's own store already did.
- Everything else of ADR-0038 stands, and matters more now that it is the default: a save nobody asked for never writes
  over a file changed on disk, never makes a deleted file again, never writes a file that was not read; a failure is said
  in the pane and tried again after the next edit.
- `0` and `false` in the configuration file, or in Settings > Documents > Editing, give back a file written by Cmd-S only.
  The field steps by 1 s (it stepped by 5).
- `DocumentAutosave()` in `SunsetDocuments`, with no settings given, still saves no file by itself: the default is the
  app's, not the library's.

## Consequences

- The sheet on closing and the question at quit are now rare for a file: they are met when a save failed, when the file
  changed on disk under the edits, or within two seconds of typing.
- With M-e (changes on disk merged by blocks), a save by itself waits while a conflict is unanswered (the owner, same day).

## The other answers of that day

Kept as decided in his absence: quitting asks about unsaved files even at `tabs.askBeforeQuit: never`; stored documents
keep themselves; a Sunset started on a file with no session shows only that file; a drop on a terminal types the path; a
dropped folder does nothing outside a terminal; Sunset is never the default app for Markdown. A document dragged from the
Library's list when a tab already shows it makes a second tab (as built), while a file opened from the Finder or the
command bar selects the tab that shows it.
