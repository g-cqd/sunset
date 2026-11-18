# Storage audit, 2026-11-18 (the owner's)

The owner's audit of `~/Library/Application Support/Sunset/` and the installed binary, given in note n22, kept as he wrote it
below; claims until probed. Probed here the same day:

| Claim | Probe | Verdict |
|---|---|---|
| The folder and the databases are readable by others (0755, 0644) | `stat` | Confirmed: the folder `drwxr-xr-x`, `library.sqlite*` and `state.sqlite*` `-rw-r--r--`; `session.sealed` alone `-rw-------` |
| The write-ahead logs hold megabytes of residue | `stat`; `PRAGMA journal_mode` | Confirmed: `state.sqlite-wal` 2.7 MB, `library.sqlite-wal` 1.3 MB; journal `wal` |
| `secure_delete` is off | `PRAGMA secure_delete` | Read `2` (FAST: overwrites in the same page only); not on |
| Everything else (cipher, layout, AAD, Keychain, HKDF, metadata in clear, signing) | — | Not probed; matches the design (ADR on sealed storage) as far as read |

---

## The audit as given

1. **Folder.** `session.sealed` (~755 KB, sealed whole), `library.sqlite` (+WAL ~1.3 MB, 2 sealed `documents` rows),
   `state.sqlite` (+WAL ~2.5 MB, 131 sealed rows: agents 3, favicons 15, history 106, permissions 6, recent-files 1),
   `Documents/` (2 sealed files, UUID names), `Blocking/` (compiled rule lists, ~28 + 24 MB; the public lists in plain text).
   Schema: `records(kind TEXT, key BLOB 16 B, sealed BLOB, sort REAL, count INTEGER)`, `meta(name, value)` with the key id.
2. **Scheme.** CryptoKit ChaChaPoly, 256-bit key; blob `"SNSL" | 0x01 | keyID (4) | nonce (12, unique across rows) |
   ciphertext+tag`; sealed against an identity (kind, file name) as associated data; the key in the login Keychain
   (`KeychainKeyVault`), HKDF derivation, a recovery code path (`sunset.recovery.v1`); rows of an absent key counted
   unreadable and never overwritten.
3. **What leaks without the key.** Per row in clear: `kind`, `sort` (exact times: every visit's), `count` (up to 52 seen),
   the 16-byte row `key` (stable, so joinable across copies); how many of each kind; the lists' file names; names, sizes and
   times of files.
4. **Not recovered.** The payloads; the key never found in plain text.
5. **Recommendations.** (1) `chmod 700` the folder, `600` the databases. (2) On close, `PRAGMA wal_checkpoint(TRUNCATE)` or
   `journal_mode=DELETE`, and `PRAGMA secure_delete=ON`. (3) Times and counts inside the sealed payload (or coarse buckets);
   opaque per-install ids for `kind`; row keys from an HMAC with a key other than the storage key. (4) Developer ID signing,
   hardened runtime, library validation; a Secure Enclave key wrapping the storage key. (5) A memory-hard KDF (Argon2id or
   scrypt) if the recovery code can be typed prose; HKDF only for random ~128-bit codes. (6) Exports sealed by default, or
   strictly opt-in with a warning.
6. **Bottom line.** Per-record AEAD with the key in the Keychain and identity binding; no break of the payloads; what is
   exposed is behaviour (counts, times, sizes, list names), in clear by design, and history residue in the WAL files.

The owner on Argon2id: "if we ever want to go that way, we can leverage our own implementation in one of our aemi package".
