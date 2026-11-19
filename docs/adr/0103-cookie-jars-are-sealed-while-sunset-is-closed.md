---
status: accepted
date: 2026-11-19
---

# 0103 — Cookie jars are sealed while Sunset is closed

## Context

Design 0007 kept two parts of t51:
- the cookie jar sealed at quit;
- caches out of backups (done: `WebKitFolders.excludeCaches`).

The encrypted image was dropped: FileVault is on, and an image would be open to every process while Sunset runs. Cookies
are session tokens (asset D1), and a copy or a backup of `~/Library` (adversary A4) holds them in the clear. Probed (diary
2026-11-19-12): flushed, then moved aside at quit, a jar is not written again by WebKit; put back before a store opens, its
cookies are read.

## Decision

- **Which jars:** the default store's jar (`~/Library/HTTPStorages/<bundle>.binarycookies`) and each profile store's
  (`WebKit/<bundle>/WebsiteDataStore/<id>/Cookies/Cookies.binarycookies`).
- **At quit:**
  - each jar is sealed after every store's cookies are flushed;
  - with the storage key, purpose `cookies`, bound to its place;
  - written 0600 beside the jar, checked, then the jar in the clear is removed.
- **At launch:** each sealed jar is put back before any store opens.
  - A jar in the clear already is newer: it stays, and the sealed one goes.
  - A sealed jar that does not open is kept.

## Consequences

- The quit answers AppKit only once this work ends or 5 s pass (`QuitDeadline`), on every path: it spun the run loop
  before, which from inside a main-actor task never ran the work (diary 2026-11-19-12).

- While Sunset runs the jars are in the clear, 0600: another program of the same user (A3) is not answered by this.
- **A crash or a forced quit** leaves the jars in the clear until the next quit.
- **A run without the store's key** (the Keychain refused) seals nothing, and starts with no cookies from the sealed jars. A
  jar written during that run is newer at the next launch, and the sealed one is then removed: those older sessions are
  lost. Kept as it is: a run without the key has already shown the person a choice.
