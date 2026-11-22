---
status: in-progress
blocked-by: nothing (ADR-0090, ADR-0091 accepted; t48 D was found moot, the KDF is this entry's own)
date: 2026-11-19
---

# 0091 — The vault: scope, store, keys, lock

Research: docs/research/credentials/vault.md. ADR-0090, ADR-0091 (proposed).

| Step | What | Status |
|---|---|---|
| A | `credentials.enabled` (off), the `SunsetCredentials` module (no UI), a vault file per vault under SunsetStorage's rules (0600/0700, `secure_delete`, nothing in the clear but id, version, sealed payload) | done 2026-11-21: `features.credentials` (off; no Settings control until a vault can be made), `VaultFile` (tests: nothing readable in the bytes, 0600/0700, a record moved to another slot or vault does not open) |
| B | The vault key, purpose keys (HKDF), sealing; red tests: a record sealed for one purpose fails as another; a changed byte fails | in-progress: records sealed with `Seal` (purpose `vaultRecord`, HKDF per purpose, bound to vault and slot); the vault key's own type and wrapping by factors (C) not done |
| C | Factors: master password (Argon2id via `AemiArgon2`, parameters measured, release, percentiles), recovery code, Touch ID (Secure Enclave, `.biometryCurrentSet`); any one or two | in-progress: master password: Argon2id 1 GiB, 3 passes, 4 lanes, measured 0.64 s p50 / 0.67 s p90 (release, 7 runs; 512 MiB×4 0.40 s); the vault key wrapped per factor (ChaCha20-Poly1305, bound to vault and factor; red first). Recovery code (32 bytes, the storage key's written form, HKDF per vault) and Touch ID (Secure Enclave P-256 + ML-KEM-1024, `.biometryCurrentSet`) done 2026-11-22, red first; the Touch ID prompt itself not seen. Two factors at once (`FactorKey.pair`) done 2026-11-22 |
| D | Locking: quit, idle (Runtime clock), screen lock, sleep, last window, by hand; secrets in locked zeroed buffers; vault windows excluded from capture | in-progress: `VaultLock`, `SecretBuffer`; every open vault locks at once (`VaultLocks`) on the app's events: sleep (the Mac's or its displays'), the screen locked, another user, quit, the last window closed (2026-11-22, `VaultLocksTests`, red first; the app's listening not seen firing). Capture exclusion comes with the vault's windows (E) |
| E | The unlock sheet, the menu, Settings' page; Help. Where: a Library section, Touch ID first (ADR-0116) | in-progress: a made vault's Touch ID slot (2026-11-22, `VaultTouchIDTests`) |
| F | Measured: unlock time, opening a 10,000-entry vault (release, percentiles) | not-started |

Not done: D's capture exclusion (with E), E–F. A vault can be made, opened and unlocked (`Vault`, its factors kept in its file: 2026-11-22), but nothing in the app does so yet; two factors at once are not yet a slot of a made vault.
