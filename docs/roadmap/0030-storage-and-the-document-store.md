---
status: in-progress (ST-1 without its "said" part, 2026-11-13)
blocked-by: nothing; roadmap 0023 (Markdown) from M-b waits for ST-4
date: 2026-11-13
---

# 0030 — Storage, sealing, and the document store

Decided with the owner in refinement session R12 (`docs/refinement/R12-storage-and-the-document-store.md`, accepted 2026-11-13),
which is the description to build from; the study behind it is `docs/research/storage/README.md`. Nothing is built.

| Step | What | Task |
| --- | --- | --- |
| ST-1 | `SunsetStorage`: one place for where each thing is, safe writing (Aemi's `AtomicFile`), versions, a file that does not read moved aside and said; the session's writer moves to it | t252 |
| ST-2 | The key (Keychain, iCloud Keychain, the recovery code) and the seal's format | t253 |
| ST-3 | `state.sqlite` (history, zoom, permissions, downloads) with sealed columns and the import of today's files; the session sealed | t254 |
| ST-4 | The document store: `Documents/`, `library.sqlite` rebuilt from the files, deleting to the Trash as plain text, moving to a file | t255 |
| ST-5 | The Documents section of the sidebar, under Favorites | t256 |
| ST-6 | Settings, Storage: places, the web store's sentence and FileVault's state, the recovery code, Export All | t257 |

## State

ST-1, 2026-11-13: `SunsetStorage` (`StoragePlaces`, `StoredFile.write` over Aemi's `AtomicFile`, `StoredFile.read` that moves a file
that does not read aside under a dated name, `StorageProblems`); the session is read and written through it (files are now
private to the person, mode 600); `SessionLocation` is gone. Probed: a session that is not JSON was moved aside as
`session.json.damaged-<date>` and the app started with a new one. Not done in ST-1: showing `StorageProblems` to the person (its
look is asked first); the other four files still write themselves (they move into the database in ST-3).

## Not done

ST-2 to ST-6, and the "said" part of ST-1. Not in this entry: search inside documents; a key per profile (asked in roadmap 0021); sealing the web store (not
possible with public API, probed 2026-11-13).
