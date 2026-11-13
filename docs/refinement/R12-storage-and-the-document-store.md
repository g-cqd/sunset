# R12 — Storage, the document store and its library (roadmap 0018)

Status: **accepted by the owner 2026-11-13** (roadmap 0030; tasks t172, t217, t135). Nothing here is built.
Input: R6 (the document behind a pane; "the in-app storage needs to be refined"), the study `docs/research/storage/README.md` of
the same day (what Sunset keeps, forms of a store, encryption, what WebKit allows, probed).

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| The form of the document store | A folder of files, one per document, each saved whole or not at all, and an index that can be rebuilt from them | "Maybe it should be backed by some db though": the index is a database (SQLite) |
| Encryption of documents | On, silently: always sealed with a key in the Keychain, nothing to set | |
| The web store | Accepted: Sunset does not encrypt it (WebKit's save and restore takes only local storage, probed); Settings say so and show whether FileVault is on | |
| History, zoom, permissions, downloads | One SQLite database with versions and migrations; the session stays a file, the configuration stays the person's | |
| What is sealed besides documents | The session file, whole; the sensitive columns of the database (addresses, titles), searched in memory | |
| A deleted document | To the Mac's Trash, as plain text (`Title.md`), readable until the Trash is emptied | |
| The key's safety net | Both: a recovery code shown once in Settings, and the key synced by iCloud Keychain when the person uses it | |
| The library | A Documents section in the tab sidebar, under Favorites | |
| A file that does not read | Moved aside (`name.damaged-date`) and said; never dropped silently | |
| Does Markdown wait for the store | Yes | |

## The outcome, as one description

Everything Sunset keeps has **one place, one way of being written and one way of failing**. A new target, `SunsetStorage`, knows
where each thing is, writes files whole or not at all (Aemi's `AtomicFile`, which forces the data and the folder to the disk),
gives every file and the database a version, and moves a file that does not read aside under a dated name and says so.

The small records (page history, site zoom, site permissions, downloads) move from four files into **one SQLite database**,
`state.sqlite`, with a schema version and migrations; the four files are imported once and moved aside. The **session** stays one
file, read whole. The **configuration** stays the person's own file.

**Documents** live in `Documents/`, one file each, and `library.sqlite` beside them holds what the library shows (title, kind,
dates, a checksum). The index is rebuilt from the files when it is missing, does not read, or disagrees with them: losing it loses
nothing. A document whose pane is closed stays there and shows in a **Documents section of the sidebar**, under Favorites, to
reopen, rename or delete. Deleting writes it as plain text into the Mac's Trash and removes it from the store. Moving a document
to a file of the person's is the same export, to a place they choose.

**Sealing.** One key, random, made on first use, in the login Keychain, synced by iCloud Keychain when the person uses it, with a
recovery code that Settings can show once. It seals every document, the session file, and the addresses and titles in
`state.sqlite` (ChaCha20-Poly1305 from the system's CryptoKit, each thing with its own nonce and its identity as associated data,
so one cannot be put in place of another, and a damaged one is detected rather than read). Nothing is asked of the person. The
web store is WebKit's and is not sealed: FileVault is its only protection, and Settings say so.

## Costs, as the owner asks to see them

- **Memory.** A document is held once, unsealed, while a pane shows it. The library's titles and the history are unsealed into
  memory at launch so that they can be searched: a history of tens of thousands of visits is a few megabytes. To be measured.
- **Speed.** Sealing is fast (the system's ChaCha20-Poly1305 does on the order of a gigabyte a second, Apple's figure to check
  here); a save's cost is the wait for the disk, as for any safe write. History search no longer uses the database's own search:
  it filters in memory, to be measured against today's on the same history.
- **Safety.** The key is one point of loss: without it every document, the session and the history are unreadable. Hence the two
  nets. A sealed file that is damaged is refused whole (no partial text). Time Machine keeps each document's versions, sealed.
- **Security.** Protected: the files at rest against another program reading them, and copies elsewhere. Not protected: a program
  that can ask the Keychain as Sunset, read Sunset's memory, or the person's Trash (plain text by his choice); the web store;
  a file the person exports.

## Said plainly

- Other tools cannot open documents in the store. To edit one elsewhere it is moved to a file first.
- Search inside documents is not part of this: at first the library finds by title. Content search needs the texts unsealed in
  memory or a sealed index; it is its own step, after Markdown.
- iCloud Keychain syncs the key, not the documents: a second Mac has the key and nothing to open with it unless the store's folder
  is brought over (a backup, a copy).
- The recovery code is the key itself in a form to write down. Whoever has it and the files reads everything.
- A document in the Trash as plain text is outside the seal by the owner's choice.
- Private pages keep nothing, as now. Profiles (roadmap 0021) get a folder each with their own `state.sqlite`; whether a profile
  has its own key is asked there.
- `MarkdownLookKit` has `DocumentFile.write` for a document that is a file of the person's (it keeps permissions and symbolic
  links); the store uses Aemi's `AtomicFile` directly.

## Steps (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| ST-1 | `SunsetStorage`: places, safe writing, versions, a file that does not read moved aside and said; the session's writer moves to it | How "said" looks (a banner, the Settings) |
| ST-2 | The key: made, kept, synced, the recovery code; the seal's format | Where the code is shown; what "restore from a code" asks |
| ST-3 | `state.sqlite`: history, zoom, permissions, downloads, sealed columns, the import of today's files; the session sealed | |
| ST-4 | The document store: `Documents/`, `library.sqlite`, rebuilding, deleting to the Trash, moving to a file | The file's name on export |
| ST-5 | The Documents section of the sidebar | Its look and order (sketches) |
| ST-6 | Settings, Storage: where things are, the web store's sentence, FileVault's state, the recovery code, Export All | |
| then | Markdown M-b onward (roadmap 0023), on this store | |
