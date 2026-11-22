---
status: accepted
date: 2026-11-22
---

# Sunset and Sunset WebKit share Sunset's data, not WebKit's

## Context

The owner (note n77): "find a way for Sunset and Sunset WebKit to share the same data". ADR-0111 made them two apps,
`studio.aemi.sunset` and `studio.aemi.sunset.webkit`, each with its own store, settings, sealing key and website data. The
research (docs/research/shared-data-between-builds-2026-11-21.md) found that WebKit's own stores cannot be shared: a newer
WebKit upgrades them in place, and an older one then stops on purpose (`RELEASE_ASSERT` in `SQLiteIDBBackingStore`).

## Decision

The owner's choices, 2026-11-22:

- **Shared:** Sunset's own data:
  - the store (session, documents, history, site settings, downloads, extensions' packages and grants);
  - the settings;
  - the key that seals them: one keychain access group, Sunset's. Both provisioning profiles already allow `TEAM.*`.
- **Apart:** WebKit's website data:
  - cookies, IndexedDB, local storage, service workers, caches;
  - their sealed forms at rest, which stay under `~/Library/WebKit/<bundle id>`.
- **Sign-ins:** carried one way, on the person's request ("Bring cookies from Sunset"), as cookies through
  `WKHTTPCookieStore`, never as WebKit's files.
- **Both running:** the second one opened says the other is open, and offers to quit it (its session saved first) or to
  quit itself.
- **Sunset WebKit's own store from before:** merged once. Its documents and history are added to Sunset's; its session and
  settings give way to Sunset's. Its folder is left as it was, as a backup.

## Consequences

- Sunset WebKit lists two keychain groups: Sunset's first, where the shared key is, then its own, so that its old key still
  opens its old store for the merge.
- The settings of Sunset WebKit from before (`~/.config/sunset-webkit`) are no longer read.
- Supersedes the part of ADR-0111 that gave each build its own store and settings. Its own website data stays.
