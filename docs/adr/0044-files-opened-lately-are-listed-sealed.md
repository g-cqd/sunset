---
status: accepted
date: 2026-11-16
---

# 0044 — Files opened lately are listed with the documents, and kept sealed

Roadmap 0031, from the owner's answers of 2026-11-16 on what was left of the Library: recently opened files are listed
with the documents; a private window hides stored documents; Escape closes the Library from anywhere in it.

## Decision

1. **The last twenty files opened, each once, the latest first** (`RecentFiles`), are rows of the Documents section among
   the documents of the store: under the day they were opened, with the time and the folder; under their kind, or by name,
   in the other orders. A file is noted when it is opened by the person: the Open panel, the Finder, a drop, the command
   bar, a link followed from a document. Restoring a session notes nothing.
2. **They are kept in the state database, sealed, each named there by a keyed hash** (a `SealedTable`, as the history and
   the downloads): the names of the person's files and folders are not written in plain. With no key in a run they last as
   long as the run.
3. **Nothing of a file is read to list it.** No date of the file, no check that it is still there (reading a folder the
   person has not opened to Sunset would make macOS ask). A file that is gone is listed, and says so when opened.
4. **A row for a file is not a document of the store**: it opens the file (the tab that shows it, if one does), is dragged
   as a file, offers Show in Finder and Remove from This List, and is never deleted from here.
5. **A private window lists no document, of the store or of the disk**, in the Library, in the panel opposite the tabs
   and in the command bar, and a file opened in one is not noted. New Document and Open File still work there: they are
   acts, not lists.
6. **The Library has the keyboard when it opens and when its section changes**: in its search field, or on the list
   itself when there is nothing to search; a click beside its rows gives it back. Escape then closes it and the pane has
   the keyboard again. While the keyboard is in a pane, Escape is the pane's (a terminal needs it).

## Not decided here

- Whether the list of files should be cleared with the history (Clear History), and whether twenty is the number.
- A key for each section.
