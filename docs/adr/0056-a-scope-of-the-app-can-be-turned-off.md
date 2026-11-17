---
status: accepted
date: 2026-11-17
---

# 0056 — Terminals, the web and documents can each be turned off

Roadmap 0033. The owner asked (2026-11-16) for "a toggle that remove all the web navigation scope, one that removes
completely the terminal from the app features, and one that removes document visualization and handling and rendering
except downloads", and answered its questions on 2026-11-17.

## Decision

| Question | The owner's answer |
| --- | --- |
| What is open when a scope is turned off | Its **tabs close, after a question**; what is **kept** of it (pinned, favourites) is **hidden and comes back** |
| When | **At once** |
| All three off | **No: at least one stays on** |
| A new tab or window with terminals off | **The command bar on an empty tab** |
| A link with the web off | **Opens in the system's default browser** |
| The scope's data | **Kept untouched, not shown** |
| A file with documents off | **Opens in its default app**; Show in Finder stays |

Decided by the builder, to be said:

1. **Three settings**, `features.terminal`, `features.web`, `features.documents`, on by default, in Settings > General >
   What Sunset does. The last one on cannot be turned off; all three off in the file is said and terminals stay on.
2. **A scope is a kind of pane** (`Scopes`): terminals, `web`, `document`. A pane of a kind that is off is never made:
   not from a menu, the + menu, the kind chooser, the command bar, a link, a restored session or a kept entry.
3. **Turning one off with something open asks** ("Turn Off and Close", with how many tabs and what happens); with
   nothing open it is done at once. Panes of that kind close in every Space (a tab of only those goes; a split keeps
   its other panes); kept entries that have such a pane are unloaded and hidden. Turned on again, they are listed again.
4. **What goes from the interface**, per scope:

   | Off | Gone |
   | --- | --- |
   | Terminals | New Terminal Tab, the kind chooser, Previous/Next Prompt, Settings > Terminal and "Programs in a terminal". A split asks, through the command bar, which tab goes beside |
   | The web | New Web Page, private windows and tabs, the History menu, Print, page Find, the command bar's addresses, searches, history and suggestions, the Library's History and Downloads, Settings > Web and "Browsing". Links go to the default browser |
   | Documents | New Document, Open File…, Save, the document items of View, the Library's Documents, the command bar's files and stored documents, Settings > General > Documents. A file opened with Sunset goes to its default app (or the Finder, when that app is Sunset); a file dropped on a terminal still types its path |

5. **With no section left**, the Library's glyph is not shown, and the panel opposite the tabs closes.

## Not done

- Sunset still declares Markdown and Mermaid in its bundle with documents off (it stays in Open With; the system cannot
  be told otherwise at run time). A file sent to it then goes to the default app.
- With the web off, downloads already listed stay reachable only from where they are (the Library's Downloads is the
  web's); the owner's "except downloads" was read as: what a page downloads stays, documents being off.
- WebKit's processes are not shown to end when the web is turned off (expected once the last page closes; not measured).
- An unloaded favourite of a new page with no address is listed as "web" when it comes back (its title was not kept).
