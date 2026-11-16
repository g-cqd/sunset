---
status: accepted
date: 2026-11-16
---

# 0040 — Files opened with Sunset open in tabs; a file dropped on a terminal is typed, never run

Decided without the owner, who was away and said to go on with sensible defaults (roadmap 0023, step M-f). Each point is
his to change.

## Decision

1. **Sunset can open Markdown, Mermaid and plain text, and is never their default.** `Info.plist` declares the three types
   with the role Editor and `LSHandlerRank` Alternate: Sunset is in Open With, a file can be dropped on its icon, and the
   person's editor stays the one a double click opens. Markdown and Mermaid are *imported* types (Sunset does not own them);
   Mermaid has no identifier of its own in the system, so `studio.aemi.sunset.mermaid` names it, conforming to plain text.
2. **A file opened with Sunset opens in a tab of the window that acts**, one per file, and a file that window already shows
   is shown instead of opened twice (its path compared after standardizing and resolving links). With no window, one is
   opened for all of them; when that window also restores a session, the files come after its tabs; when there is no
   session, they are its only tabs (no terminal is started beside them).
3. **SwiftUI makes no window for a file.** Declaring document types makes a `WindowGroup` take the open event: it made a
   second window for the file and closed the first, which left a blank window (seen). `handlesExternalEvents(matching: [])`
   turns that off, and with it the first window AppKit would make for a Sunset started on a file; `AppActions.open(files:)`
   opens that window itself.
4. **A file dropped on a terminal pane is typed there, as a paste**: its path, in single quotes unless it is only letters,
   digits and `/ . _ - + , : @ %`, followed by a space; the pane takes the keyboard. Nothing is run: no newline is ever
   typed. Dropped on any other pane, each file opens as a document; folders do nothing there.
5. **A dropped name that holds a control character is never typed**, nor the names dropped with it (C0, DEL, C1, U+2028,
   U+2029). A dropped name is not the person's typing: it can come from an archive or a download. Single quotes stop the
   shell from reading it, not its line editor from acting on it (an interrupt ends the line; what follows is then a
   command). White paper §9: what an untrusted source can make the terminal do has a policy and a test (`FileDropTests`).
6. **The command bar opens a file whose path is typed** (from `/`, `~/` or `file://`, to a file that is there): the first
   row, before the search. Folders and files that are not there give no row. Stored documents whose title matches the words
   typed come after the typed row, except those already in a tab.

## Not decided here

- Whether a dropped folder on a non-terminal pane should open a terminal there.
- Whether a path typed in the bar that is a folder should open a terminal there.
- Opening a file at a line (`file:line`), and relative paths in the bar.
