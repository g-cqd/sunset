# Storage: what Sunset keeps, a store for documents, and encryption

A study for tasks t217 (consolidate the app's storage), t135 (encryption for the web store and in-app documents) and the
refinement t172 (Sunset's own document store and its library). Written 2026-11-13. Statements are claims unless the probe table at
the end says otherwise. Nothing here is decided: the refinement decides.

## 1. What Sunset keeps today

| What | Where | Form | Written | Holds |
| --- | --- | --- | --- | --- |
| Configuration | `~/.config/sunset/config.json` (or `$XDG_CONFIG_HOME`), themes beside it | JSON with comments, the person's own file | whole file, temp and rename | settings; no secrets |
| Session | `~/Library/Application Support/Sunset/session.json` | JSON, `version: 2` | whole file, temp and rename, on each change (debounced) | open tabs, their folders, addresses, a page's history (base64), Favorites, kept terminals' commands (sealed) |
| Page history | `…/Sunset/history.sqlite` | SQLite, one table | per visit | every address visited, titles, counts, dates |
| Site zoom | `…/Sunset/site-zoom.json` | JSON | whole file | host to zoom |
| Site permissions | `…/Sunset/site-permissions.json` | JSON | whole file | host to camera, microphone, location, pop-ups, sound, notifications |
| Downloads | `…/Sunset/downloads.json` | JSON | whole file | files downloaded, resume data |
| The seal's key | login Keychain, generic password `studio.aemi.sunset.command-seal` | 32 bytes | once | the key that seals kept commands |
| Website data | `~/Library/WebKit/studio.aemi.sunset/` (WebKit's) | WebKit's own files | by WebKit | cookies, local storage, IndexedDB, caches, service workers |
| Window frames, panel states | `~/Library/Preferences/studio.aemi.sunset.plist` | defaults | by AppKit | sizes and positions |
| Private pages | memory only | | | nothing kept |

Five files, three forms (JSON, SQLite, WebKit's), one writer each, no shared code for where a file is, how it is written, its
version, or what happens when it does not read. "Temp and rename" here is Foundation's `.atomic`: the data is not forced to the
disk before the rename, so a power loss can leave an empty or short file under the final name. Only the session has a version. A
file that does not parse is treated as absent (the session: no tabs restored). Every file is readable by any program the person
runs.

## 2. What the document store must do (refinement R6)

A new document lives in Sunset by default and can be moved to a file; one whose pane is closed stays in a library to reopen or
delete; documents are Markdown, Mermaid or plain text; one text, one undo history and one edited state per document however many
panes show it; saving is whole or not at all; one damaged file must not lose every document; a backup; encryption is studied with
the web store's.

## 3. Forms a document store can take

| | A. A folder of files and an index | B. One SQLite database | C. One container file of our own |
| --- | --- | --- | --- |
| A document is | a file (`<id>.md`), written by `AtomicFile` | a row | a record in a log |
| Damage to one file loses | that document, or only the index (rebuilt from the files) | possibly every document | possibly every document |
| The library (titles, dates, search) | an index beside the files, rebuildable | queries; full-text search (FTS5) | an index we write |
| Backup | Time Machine keeps each file's versions; a copy is a folder | the database's backup API; Time Machine copies the whole file at each change | ours to write |
| Opened by other tools | yes (unless encrypted) | no | no |
| Moved to a file | a copy | an export | an export |
| Encrypted | each file sealed on its own; names and the index too | the whole file needs SQLCipher (not the system's SQLite), or each row sealed (then no search inside) | designed in |
| Code to write and prove | little: `AtomicFile` exists (AemiMarkdown ADR 0008) | moderate; SQLite is already linked for history | much, and the risk is ours |

A keeps the property R6 asked for by construction. B gives search and one transaction across documents, at the price of one file
that holds everything. C is B's risk without SQLite's maturity.

## 4. Encryption

**What it would protect against.** FileVault (the system's, if the person turned it on) already encrypts the disk while the Mac
is off or the account is logged out. Encryption by Sunset adds protection only against: another program run by the same person
reading Sunset's files; a copy of the files elsewhere (a backup disk, a synced folder); someone at the unlocked Mac without the
passphrase, if there is one. It does not protect against a program that can read Sunset's memory or inject into it.

**Keys.** (1) A random key in the login Keychain: no passphrase, unlocked with the account; other programs must ask the Keychain
(the person sees a prompt for a program not signed as Sunset). Sunset already keeps one key this way. (2) The same key wrapped
by a passphrase through Argon2id: Aemi has it (`AemiArgon2`, RFC 9106, its numbers are Aemi's); a forgotten passphrase loses
everything. (3) A key held by the Secure Enclave and released by Touch ID: the strongest on this Mac, tied to this Mac (a backup
restored elsewhere does not open).

**Sealing.** CryptoKit's ChaCha20-Poly1305 or AES-GCM (the system's; Sunset already links swift-crypto): each document sealed
whole with its own nonce, the document's id as associated data so a file cannot be swapped for another. An edit rewrites the file.

**The web store.** WebKit decides where and how website data is kept. The public API gives: the default store; a store per
identifier (`WKWebsiteDataStore(forIdentifier:)`, macOS 14, the base for profiles); a store in memory only (private pages); and,
since macOS 26, `fetchData(of:)` and `restoreData(_:)`. Probed here (below): on macOS 27.0.1 `fetchData` accepts only local
storage; cookies, IndexedDB and the caches are refused. So an app cannot keep a store in memory and persist it sealed itself:
cookies could be saved through `WKHTTPCookieStore`, but IndexedDB and service workers would be lost at each quit. A file-protection
class can be set on a file on this Mac (probed: it reads back); whether WebKit's files can be given one, and what it enforces on a
Mac, is not probed. **Claim: Sunset cannot encrypt the web store beyond what FileVault does**, short of private API or keeping
the whole WebKit folder on an encrypted disk image.

## 5. A proposal to discuss in the refinement

1. **Documents: form A.** `…/Sunset/Documents/<id>.md` (or `.mmd`, `.txt`), each written by `AtomicFile`, and `library.sqlite`
   beside them (id, title, kind, dates, a checksum), rebuilt from the files when it is missing or disagrees. Deleting moves a
   document to `Trash/` inside the store for a time. Time Machine is the backup; "Export All" writes a folder.
2. **Encryption of documents: optional, off by default**, by the first kind of key; a passphrase as a later choice. Sealed files
   are `<id>.sealed`; the index holds no text of the documents, and its titles are sealed too.
3. **The small records (history, zoom, permissions, downloads): one `state.sqlite`** with a schema version and migrations, since
   they are records that are queried and history is already SQLite. The session stays a JSON file (one snapshot, read whole, useful
   to read by eye), written by `AtomicFile`. The configuration stays the person's file.
4. **One place and one piece of code** for where each thing is (`StorageLocation`), how it is written, its version, and what is
   done with a file that does not read: it is moved aside (`name.damaged-date`) and said, never silently dropped.
5. **Profiles (roadmap 0021)** get a folder each (`Profiles/<id>/` with its own `state.sqlite` and a WebKit store by identifier);
   private pages keep nothing, as now.
6. **The web store is not encrypted by Sunset**; the Settings say so, and say whether FileVault is on.

## 6. Probes

| Claim | Probe | Verdict |
| --- | --- | --- |
| The inventory of section 1 | `grep` of the sources for paths and writers; `ls` of the folders | As listed (5 files, 1 Keychain item, WebKit's folder 7.4 MB today) |
| An app can save a website store itself with `fetchData` | a tool: every type of `allWebsiteDataTypes()` asked one by one, on a store in memory and on one by identifier | Only `LocalStorage` is accepted; `Cookies`, `IndexedDBDatabases` and the others: "This API does not support fetching" |
| `restoreData` brings back what `fetchData` gave | the same tool, into a second store | No error; cookies are not part of it |
| A file-protection class can be set on this Mac | `FileManager.setAttributes([.protectionKey: .complete])`, read back | Set and read back as `NSFileProtectionComplete`; what it enforces not probed |
| `AtomicFile` forces the data to the disk and keeps the old file on failure | AemiMarkdown `AtomicFileTests` (4) | Pass |

Not probed: SQLite's behaviour on a damaged page (`PRAGMA integrity_check`, recovery); Time Machine's handling of a folder of small
files against one database; the Keychain prompt another program sees; the Secure Enclave key; the cost of sealing a large document
at each save; SQLCipher.
