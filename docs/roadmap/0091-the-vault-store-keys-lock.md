---
status: in-progress
blocked-by: nothing (ADR-0090, ADR-0091 accepted; t48 D was found moot, the KDF is this entry's own)
date: 2026-11-19
---

# 0091 — The vault: scope, store, keys, lock

Research: docs/research/credentials/vault.md. ADR-0090, ADR-0091 (proposed).

| Step | What | Status |
|---|---|---|
| A | `credentials.enabled` (off), the `SunsetCredentials` module (no UI), a vault file per vault under SunsetStorage's rules (0600/0700, `secure_delete`, nothing in the clear but id, version, sealed payload) | in-progress: `features.credentials` (off, read and written, no Settings control until there is a vault; 2026-11-21) |
| B | The vault key, purpose keys (HKDF), sealing; red tests: a record sealed for one purpose fails as another; a changed byte fails | not-started |
| C | Factors: master password (Argon2id via `AemiArgon2`, parameters measured, release, percentiles), recovery code, Touch ID (Secure Enclave, `.biometryCurrentSet`); any one or two | not-started |
| D | Locking: quit, idle (Runtime clock), screen lock, sleep, last window, by hand; secrets in locked zeroed buffers; vault windows excluded from capture | not-started |
| E | The unlock sheet, the menu, Settings' page; Help | not-started |
| F | Measured: unlock time, opening a 10,000-entry vault (release, percentiles) | not-started |

Not done: everything but the switch.
