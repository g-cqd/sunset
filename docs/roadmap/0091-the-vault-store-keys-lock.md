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
| C | Factors: master password (Argon2id via `AemiArgon2`, parameters measured, release, percentiles), recovery code, Touch ID (Secure Enclave, `.biometryCurrentSet`); any one or two | in-progress: master password: Argon2id 1 GiB, 3 passes, 4 lanes, measured 0.64 s p50 / 0.67 s p90 (release, 7 runs; 512 MiB×4 0.40 s); the vault key wrapped per factor (ChaCha20-Poly1305, bound to vault and factor; red first). Recovery code, Touch ID, two factors: not done |
| D | Locking: quit, idle (Runtime clock), screen lock, sleep, last window, by hand; secrets in locked zeroed buffers; vault windows excluded from capture | not-started |
| E | The unlock sheet, the menu, Settings' page; Help | not-started |
| F | Measured: unlock time, opening a 10,000-entry vault (release, percentiles) | not-started |

Not done: C's recovery code and Touch ID, D–F; a vault is not yet made or shown anywhere.
