# 0007 — Security, data handling and safety: one scope (draft, 2026-11-19)

Status: **draft for the owner.** It puts the open security points (0051, 0012, t13, t14, t98), the credentials staging
(0090–0099), and what the realism study found (docs/research/security-realism-2026-11-19.md) into one scope. Threats:
docs/design/0006-threat-model.md.

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
| Secret | Cookies, tokens (WebKit) | WebKit's jar (clear) → sealed by Sunset at quit (planned) | ADR-0081: kept sites only | Never by Sunset | Clearing at quit; per site |
| Secret | Storage key, recovery code | Keychain (→ Secure Enclave wrap; data-protection class after t49) | The install | Recovery code shown once | Reset |
| Personal | History, sessions, tabs, permissions, downloads list, recent files, favicons | `state.sqlite`, `session.sealed`, sealed (metadata sealed with t48 C) | Settings' retention | Export (plain, 0600, warned); sealed backup | Clear by kind; per site |
| Personal | Documents | `Documents/`, sealed | Until deleted | Export; move to a file | Trash as plain text (ADR-0038's rules) |
| Personal | WebKit's cache, website data, HSTS, statistics | WebKit's folders (clear, 0700) | ADR-0081 | Never by Sunset | Clearing; out of backups (planned) |
| Transient | Clipboard, terminal output, scrollback | Memory; pasteboard | The session; concealed clipboard cleared | The person | Quit |
| Config | Settings, block lists | `~/.config/sunset`, `Blocking/` | Always | The person's files | The person |

Each row's "at rest" and "deleted by" gets a test that reads the files, as 0051 A/B's tests do.

## The scope, by layer

| Layer | What | Source |
|---|---|---|
| **Platform** | Developer ID, hardened runtime, library validation, notarisation; then the Keychain's protection class, iCloud | t49 |
| **Storage** | Format 2 (metadata sealed, HMAC keys); Secure Enclave wrap of the storage key; sealed backup of everything; exports 0600 with a warning; the cookie jar sealed at quit; caches out of backups | t48 C/E (split), new |
| **Credentials** | Vault, entries, one-time codes, filling and saving, backups and imports, sync with anti-rollback, hardware keys, Apple's side | 0091–0098 |
| **Web** | Per-navigation protections (HTTPS upgrade with a warning, a hardened level without JIT, GPC); Safari's APIs (t98); payments (0099); permissions in one policy table; extension policy (t14); DNS (t13); block lists (n58: other lists, performance) | new, t98, 0099, t14, t13, t109 |
| **Terminal** | Fuzz targets; secure keyboard entry; a paste warning; the control socket's authentication with remote control | 0012, new, 0016 |
| **Assurance** | The threat model kept current; a test per data-map row; handler fuzzing; restore tests | new |

## Staging proposed (the owner orders)

| Stage | What | Why first |
|---|---|---|
| S1 — cheap and high | HTTPS upgrade (done: ADR-0102, also the hardened mode and GPC as settings); secure keyboard entry; paste warning; exports 0600 with a warning; caches out of backups; the cookie jar 0600 check (0058 1.6) | Hours each; close real gaps (A1, A3, A4, A6) |
| S2 — storage format 2 | t48 C (metadata sealed, HMAC row keys, reseal migration); the Secure Enclave wrap; the sealed backup format (shared with the vault) | The foundation the vault reuses |
| S3 — the vault, first release | 0091, 0092 (model, editor, notes, files, history), 0093 | The owner's main request; no t49 needed |
| S4 — the vault in pages and across Macs | 0094 (filling, saving), 0095 (imports, KDBX), 0096 (sync through a folder, anti-rollback) | Highest risk (A1 fills, A7): after the model is stable |
| S5 — hardening and keys | The hardened level without JIT (measured), GPC; fuzz targets; 0097 with the owner's key; the cookie jar sealed at quit; the permissions table | Needs measurements or the owner's hardware |
| S6 — Apple's side | t49 → 0098 (passkeys, credential provider, Credential Exchange, iCloud); 0099 on screen | External: the certificate, Apple's grant |
| Later | t13 DNS; extensions with their policy (t14); the own WebKit (0048) | Large, lower worth now |

**Dropped:** t48 D (the recovery code needs no KDF); t51's encrypted image (low worth with FileVault on, open while Sunset
runs); t59's further runs.

## Open for the owner

Answered 2026-11-20 (roadmap 0100 C): 1, allowed with a setting to turn it off; 2, no (the owner has not seen a Keychain prompt
after an install); 3, bundled and refreshed (ADR-0108); 4, yes, covered beyond the cookie jar. The drops below are confirmed.
The threat model is to be hardened and refined with the state of the art before it is accepted.


1. OSC 52 write allowed by default (ADR-0010's open question)?
2. Does macOS ask for the Keychain after each install of an ad hoc build?
3. The Public Suffix List and Apple's password-manager-resources as data dependencies (§8)?
4. Is A4 (copies of `~/Library`, backups) a threat you want covered for WebKit's data beyond the cookie jar?
