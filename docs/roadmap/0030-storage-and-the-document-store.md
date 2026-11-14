---
status: in-progress (ST-1 to ST-3 done, 2026-11-14)
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

The "said" part of ST-1, 2026-11-14: `StorageProblemsBanner`, at the top of every window: the sentence, Show in Finder, a button
that puts it away. Seen with a session that is not JSON (`docs/research/storage/damaged-banner-2026-11-14.png`).

ST-2, 2026-11-14: `StorageKey` (32 random bytes; a key per purpose derived by HKDF-SHA256), `StorageKeyring` over a `KeyVault`
(`KeychainKeyVault`: a generic password of the login Keychain, this Mac only; `MemoryKeyVault` for tests), the recovery code (the
key and two check bytes in Crockford's base 32, eleven groups of five, read back in any case with O, I, L forgiven), `Seal`
(ChaCha20-Poly1305, a nonce each time, the purpose and the thing's identity bound in; its header names the key, so "sealed with
another key" is told apart from "damaged"). 19 tests; the Keychain vault probed once on the real Keychain under a name of its own
(`SUNSET_KEYCHAIN_TEST=1`), which it removed. Nothing is sealed yet, and no key exists in the Keychain until ST-3 uses one.

ST-3, 2026-11-14: `StateDatabase` (`state.sqlite`: a version, a check at each open, set aside when it does not read, left
alone when sealed with another key) and `SealedTable` (each record sealed on its own under a keyed hash of its name, two plain
numbers beside it; `SealedRows` opens them at once or on every core off the main actor). Page history, site zoom, site
permissions and downloads are records of it; the history is held and searched in memory (`HistoryStore`, measured in R12). The
session is `session.sealed` (`SealedFile`). `AppStorage` opens it all once: the key from the Keychain for the person's setup, from
a file beside a named setup's files (`FileKeyVault`: tests never touch the Keychain); sealed things without their key are not
given a new one. The five plain files of before are taken in once, checked, and put away (the Trash; removed for a named setup).
Seen on a folder of old files: they went, nothing of them is in the new files in the clear, the History menu lists the imported
pages after a relaunch; with a wrong key both are said locked and the session file is byte for byte the same. 997 tests.

## Not done

ST-4 to ST-6. In ST-3: the History menu and panel are empty for the moment a long history takes to be read (they fill when it
arrives); a database written by an earlier version has no migration yet (there is only version 1); whether the old files are
trashed or deleted is to be reassessed with the owner (t258); the person's own setup has not been run on it (the installed app
is still the build of before: installing it imports and seals the owner's own files).
