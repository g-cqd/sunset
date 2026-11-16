---
status: not-started
blocked-by: its own questions (below); nothing built
date: 2026-11-16
---

# 0033 — A scope of the app can be removed by a setting: the web, terminals, documents

Asked by the owner on 2026-11-16. Task t282. Nothing is built, and nothing below is probed: what the code would have to
change is read from it, not tried.

## What he asked

In his words: "i'd like that you add to the roadmap settings to remove completely a scope of the app, for example web,
terminals, and documents: a toggle that remove all the web navigation scope, one that removes completely the terminal from
the app features, and one that removes document visualization and handling and rendering except downloads for example".

Three toggles, then, each removing one scope **completely**: not a hidden menu item, but an app that, with the web off, is
a terminal and a Markdown editor and nothing else.

## What a scope is today (read from the code, 2026-11-16)

A pane has a kind (`terminal`, `web`, `document`, `settings`; `PaneDescriptor`, `PaneContentKinds.make`). A scope is a kind
and everything that exists only for it:

| Scope | Where it shows |
| --- | --- |
| Terminals | New Terminal Tab (the + menu, File, the kind chooser); the default kind of a new tab and of the first window; a file dropped on a terminal pane; Settings > Terminal; shell integration; kept terminals in Favorites; the busy-tab warnings at close and quit |
| The web | New Web Page and New Private Tab/Window; the History menu and Cmd-Y; the command bar's addresses, suggestions and search; the Library's History and Downloads; Settings > Web and the websites' part of Privacy; links followed from a document or a terminal; the site permissions, the zoom per site, the web data store |
| Documents | New Document, Open File…, Cmd-S; the Library's Documents and the store behind it; the command bar's Open rows and stored documents; a file dropped on a pane; Settings > General > Documents; the document types in `Info.plist` (Open With) |

## What "removed" would have to mean (claims, to settle with him)

1. Nothing of the scope can be made: no menu item, no row, no key, no kind in the chooser, no section in Settings (or the
   section says the scope is off, with the toggle), no section in the Library.
2. Nothing of the scope runs: with the web off no web view is ever made and WebKit's processes do not start; with terminals
   off no shell is started; with documents off no file is read as a document and no store is opened for them.
3. What reaches the app from outside goes elsewhere: a link clicked with the web off opens in the system's browser; a file
   opened with Sunset with documents off is refused or handed to the system. Anything an untrusted program can ask for
   through a removed scope (a terminal's OSC 8 link, a page asking to open a file) needs its policy and its test (white
   paper §9).
4. His exception: with documents off, **downloads stay** (a page still downloads; the file is not opened in Sunset).

## Questions before anything is built

| Question | Why it has to be asked |
| --- | --- |
| The tabs of a scope that are open, kept or saved when it is turned off | Closed after asking (unsaved edits, running commands)? Kept as a placeholder that comes back with the toggle? Favorites of that kind? |
| Can all three be off at once | A window then has nothing to show but the settings |
| What a new window and a new tab are with terminals off | Today both are a terminal |
| Does the toggle act at once or at the next start | "Nothing runs" is simplest to guarantee from the start of the process |
| Is the data of a scope kept while it is off | History, site permissions, the web data store, the stored documents: kept untouched, or offered for removal |
| Open With for Markdown with documents off | The types are declared in the bundle and cannot be taken back at run time: Sunset stays in the Finder's list |
| The names | `features.web`, `features.terminal`, `features.documents`? Where in Settings: General, or a section of its own |
| "Except downloads for example" | Which other exceptions he has in mind: the downloads' list only, or also showing a downloaded file in the Finder, printing a page to PDF |

## Not done

Everything. No ADR is written: there is no decision yet beyond wanting the three toggles.
