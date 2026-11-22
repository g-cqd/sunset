# 0007 — Security, data handling and safety: one scope (as of 2026-11-22)

Status: the scope worked from; its open questions were answered on 2026-11-20. It puts security, the credentials work and what the realism study found
(docs/research/security-realism-2026-11-19.md) into one scope. Threats: docs/design/0006-threat-model.md.

## Principles

1. **Nothing in the clear that Sunset can seal.** If it is in the clear, it is because the system needs it (the Keychain
   item's name, WebKit's own stores until sealed), and the data map says so.
2. **One record format, one sealing, one backup.**
   - Every store of Sunset's (state, documents, vaults) holds `id, version, sealed payload`.
   - Keys are derived per purpose from one key per store.
   - One backup format carries any of them.
3. **Keys by role.**
   - The storage key opens with the Mac (Keychain; Secure Enclave wrap).
   - A vault key opens only with the person (a factor).
   - No key is ever written in the clear, and none is sealed under a key weaker than itself.
4. **Untrusted input has a policy and a test** (white paper §9): pages, terminal output, extensions, sync data, imports.
5. **Sunset leaves no trace of itself in a page** (ADR-0089). What it does in a page, it does from its own world.
6. **The person's act before anything that leaves or fills:** fills, saves, shares, exports, payments.
7. **Safety: nothing is lost by Sunset.**
   - Atomic writes.
   - Unreadable data is kept, never overwritten.
   - Restores are tested.
   - A recovery path for every key.

## The data map

| Class | Data | At rest | Kept for | Leaves Sunset by | Deleted by |
|---|---|---|---|---|---|
| Secret | Vault entries, files, codes | Vault file, sealed by the vault key | Until deleted; history by count or age | Sealed backup; sync (sealed); fill on act; export with warning | The person; tombstones synced |
| Secret | Cookies, tokens (WebKit) | WebKit's jars, sealed by Sunset while it is closed | ADR-0081: kept sites only | Never by Sunset (Sunset WebKit may bring Sunset's, on request) | Clearing at quit; per site |
| Secret | Storage key, recovery code | The data-protection keychain, wrapped by the Secure Enclave | The install | Recovery code shown once | Reset |
| Personal | History, sessions, tabs, permissions, downloads list, recent files, favicons | `state.sqlite`, `session.sealed`, sealed with their times, counts and kinds (format 2) | Settings' retention | Export (plain, 0600, warned) | Clear by kind; per site |
| Personal | Documents | `Documents/`, sealed | Until deleted | Export; move to a file | Trash as plain text (ADR-0038's rules) |
| Personal | WebKit's cache, website data, HSTS, statistics | WebKit's folders (0700); sites' storage sealed while Sunset is closed; caches out of backups | ADR-0081 | Never by Sunset | Clearing |
| Transient | Clipboard, terminal output, scrollback | Memory; pasteboard | The session; concealed clipboard cleared | The person | Quit |
| Config | Settings, block lists | `~/.config/sunset`, `Blocking/` | Always | The person's files | The person |

Each row's "at rest" and "deleted by" is meant to have a test that reads the files; the state database's and WebKit's
folders have theirs (`StateDatabaseHardeningTests`, `WebKitFoldersTests`).

## Where each stage stands

| Stage | What | State on 2026-11-22 |
|---|---|---|
| S1 — cheap and high | HTTPS upgrade, a hardened mode and GPC as settings (ADR-0102); secure keyboard entry; a paste warning; exports 0600 with a warning; caches out of backups; WebKit's folders 0700/0600 | Done |
| S2 — storage format 2 | Metadata sealed, keyed tags, the reseal migration; the Secure Enclave wrap of the storage key; the sealed backup format (shared with the vault) | Done, except the sealed backup format |
| S3 — the vault, first release | The model (vault file, factors: master password, Touch ID, recovery code; the lock; zeroed buffers); the editor, notes, files, history | The model is built (`SunsetCredentials`); no window shows a vault yet |
| S4 — the vault in pages and across Macs | Filling and saving; imports (KDBX); sync through a folder with anti-rollback | Not built |
| S5 — hardening and keys | The hardened level without JIT (measured); fuzz targets; hardware keys; the cookie jars sealed at quit; one table of every permission's policy | The cookie jars and sites' storage are sealed at quit; the rest is not built |
| S6 — Apple's side | Developer ID, hardened runtime, library validation, notarisation; then passkeys, the credential provider, Credential Exchange, iCloud | Signed and notarised; the rest is not built |
| Later | Encrypted DNS; extensions with their policy; Sunset's own WebKit | Extensions with their policy (ADR-0113) and Sunset WebKit are built; DNS is not |

**Dropped:** a KDF for the recovery code (it needs none); an encrypted disk image (low worth with FileVault on, open while
Sunset runs).

## Decided

1. A program may write the clipboard (OSC 52) by default; a setting (`terminal.clipboardWrite`) turns it off.
2. No Keychain prompt was seen after an install.
3. The Public Suffix List and Apple's password-manager-resources are bundled data, refreshed by a script (ADR-0108).
4. Copies of `~/Library` and backups (A4) are covered for WebKit's data beyond the cookie jars: sites' storage is sealed
   too.
