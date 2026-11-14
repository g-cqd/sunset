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

## Answers at the steps (2026-11-14)

| Step | Question | Answer |
| --- | --- | --- |
| ST-1 | How a file that did not read is said | Both: a banner at the top of the window, once, and the list stays in Settings (ST-6: the files set aside are listed from the folder) |
| ST-2 | iCloud Keychain needs an entitlement Sunset does not have (probed: a synced item is refused, -34018, for an ad hoc and for an unentitled build) | The key with its recovery code now, in the login Keychain of this Mac. The owner: "icloud sync should come for the whole software if we decide to connect to it": a later decision for the whole app, not for the key alone |

| ST-3 | What becomes of the plain files once they are imported (a plain copy left in the folder would defeat the sealing) | First "Delete"; then: "maybe the import should put things in the trash as you proposed initially, i let you reassess the topic later". Built as the choice that destroys nothing: the person's own files go to the Mac's Trash; a named setup's (a test's) are removed. To be reassessed (task t258) |

| ST-4 | What a document is called; what a new one is | Named from its content; a new document is Markdown |
| ST-5 | The layout (sketches `docs/research/storage/st5-documents-sketch.png`) | **A**: a small "Documents" heading with a + and a chevron that folds it, the documents under it. And more, in his words below |
| ST-5 | An open document (sketches `st5-open-sketch.png`) | **2**: in place, as a Favorite: its row in Documents is the tab; a minus closes the pane, the document stays listed |
| ST-5 | The order | The latest changed first; "propose sorting options" |
| ST-5 | With no document yet | The heading is there, with its + |
| ST-5 | Deleting from the row's menu | At once (the plain text is in the Mac's Trash) |
| ST-5 | When, since nothing shows a document yet | After the pane: Markdown M-b and M-c first, then ST-5, then ST-6 |

The owner at ST-5 (2026-11-14), beside choosing A: "i believe documents should be movable across tabs as standard tabs, and i'd say
we should have a way to toggle having a specific section for documents, but i would imagine, we could have the documents in the
opposite sidebar (the one with the history) and we could switch there between history or documents or other things, and we could
have a setting that would allow having them in an extended original sidebar where it would show history, documents, tabs as
sectionned tabs that would change the sidebar content either for the original one or the opposite one, check arc behaviour".

Read as four things, to be shown as sketches before ST-5 is built (roadmap 0031, task t259): a document's row is dragged as a tab's
is (into Favorites and their folders, among the tabs); a setting shows or hides the Documents section of the tab sidebar; the panel
on the opposite side, which today is the history, becomes a place with sections (History, Documents, others) and a way to switch;
and a setting puts that switch in the tab sidebar itself instead (Tabs, Documents, History), changing what the sidebar shows.

What iCloud Keychain would need, when it is decided: an App ID `studio.aemi.sunset` in the developer account with the Keychain Sharing
capability, a Developer ID provisioning profile for it embedded in the app, the `keychain-access-groups` entitlement in `project.yml`,
and the key moved to the data protection keychain as a synchronizable item.

## Costs measured at ST-3 (release build, a history of 50,000 pages, 2026-11-14; another build was using the machine)

| | Before: SQLite in the clear, searched by SQL | After: sealed records, held and searched in memory |
| --- | --- | --- |
| Opening | 0.12 ms (nothing read) | The main actor is held about 12 ms (the sealed bytes are read); all of it is in memory after about 98 ms, opened off the main actor on every core. A history under 2,048 pages is opened at once, about 2 µs a page |
| Memory | SQLite's own cache (not measured) | 24 MB (about 490 bytes a page) |
| A search | 1.5 ms median, 17 ms p90, 19 ms p99 | 0.65 ms median, 6.5 ms p90, 8.6 ms p99 |
| The latest 500 | 0.21 ms | 0.02 ms |
| A visit | 0.40 ms (a wait for the disk each time) | 0.03 ms (the database orders its writes and does not wait at each: a power loss can lose the last visits) |
| Filling 50,000 | 20.6 s | 3.2 s |
| On disk | 11.1 MB | 16.8 MB (each record carries 37 bytes of seal and 16 of its name's hash) |

The owner's own history today is 30 pages. What the memory buys: nothing of the history is in the file in the clear, not even
what names a record.
