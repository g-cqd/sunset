---
status: done
blocked-by: nothing
date: 2026-11-21
---

# 0111 — Importing from other browsers, and the welcome (note n75; task t150)

The owner, 2026-11-21: import data, bookmarks, profiles, containers and extensions from Chrome, Firefox, Safari "or almost any
other browser", turned into Sunset's Spaces, folders and profiles; offered in a welcome at the first start, opened by the
sunset shader turning into a window that asks for the main preferences (features, security model, default browser, what
shows at start) and the imports.

How things map:

| Theirs | Sunset's |
|---|---|
| A browser profile (Chrome's profile folder, Firefox's profile) | a Space, with a profile of its own when the person asks |
| Bookmarks bar / toolbar, other bookmarks, mobile | the Space's Favorites: one folder per root, the bar's at the top |
| A bookmark folder | a folder; deeper than `Favorites.maximumDepth`, its contents go in the deepest folder there may be |
| A bookmark | an entry that is not open, homed on a web pane at its address |
| A Firefox container | a profile (website data apart), the Space's (roadmap 0021) |
| An extension | its store page or its package, through roadmap 0109's install (granted by the person, never silently) |
| History, cookies, passwords | not now: passwords belong to the vault (0091–0095); cookies are another engine's encrypted store |

| Step | What | Status |
|---|---|---|
| A | The neutral tree (`SunsetImport`: folders and links) and its conversion to `Favorites`, depth and count limits kept, only `http`/`https`/`file` addresses | done (diary 2026-11-21-11) |
| B | Chromium's `Bookmarks` JSON (Chrome, Canary, Chromium, Brave, Edge, Vivaldi, Opera, Arc's bookmarks) and `Local State`'s profile names | done as readers (diary 2026-11-21-11) |
| C | Netscape bookmark HTML: what every browser exports, the "any other browser" path | done as a reader (diary 2026-11-21-12) |
| D | Firefox: `profiles.ini`, `places.sqlite` read from a copy (Firefox locks it), `containers.json` | done as readers (diary 2026-11-21-12); reading the person's own needs macOS's consent (probed: refused from here) |
| E | Safari: `Bookmarks.plist` behind Full Disk Access (macOS refuses it otherwise; probed: not readable from here), Reading List as a folder | done as a reader; the window explains the access (diary 2026-11-21-14) |
| F | Extensions: the installed list per profile, matched to their store pages, offered to install | done: listed with Open Store Page; Chrome's own left out (diary 2026-11-21-14) |
| G | The Import window (File ▸ Import from Another Browser…): browser, profile, an exported file, into a new Space or this one | done, seen (diary 2026-11-21-14); not done: the command bar's row, containers made profiles |
| H | The welcome: the shader's opening, then preferences (feature scope, security model, default browser, search engine, `tabs.start`) and the imports; once, and again from Help; the main window after it | done (diary 2026-11-21-15); not seen: the HDR sun, accent colours in an active window |

Not done: Firefox containers as profiles; the command bar's row; a real import of bookmarks seen on screen (this Mac's browsers hold none Sunset may read without Full Disk Access).
