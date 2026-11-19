---
status: in-progress
blocked-by: the owner's word on ADR-0090 to ADR-0099 (all proposed)
date: 2026-11-19
---

# 0090 — Credentials, passwords, hardware keys and payments: research and staging

The owner, 2026-11-19: Apple Passwords, Sunset's own password management as a scope (lockable, backupable, synced), custom
entries with typed fields, notes, files, TOTP, YubiKeys; "please stage the tasks and the roadmap and the adrs". Research:
docs/research/credentials/; probes: diary 2026-11-19-06.

| Step | What | Status |
|---|---|---|
| A | Probe what an ad hoc signed Sunset gets (keychains, Secure Enclave, Touch ID, smart cards, WebAuthn, Apple Pay, Apple's helper), read Apple's documentation, the standards | done |
| B | Research files, ADR-0090 to ADR-0099 proposed, roadmap 0091–0099, one task each | done |
| C | The owner decides: the ADRs, the order below, the data dependencies (Public Suffix List; Apple's password-manager-resources) | not-started |

The order proposed (the owner reorders):

| # | Roadmap | Needs |
|---|---|---|
| 1 | 0091 The vault: scope, store, keys, lock | t48 D's Argon2 decision (shared) |
| 2 | 0092 Entries: templates, typed fields, constraints, layout, notes, files, history | 0091 |
| 3 | 0093 One-time codes | 0092 |
| 4 | 0094 Filling and saving in pages | 0092 |
| 5 | 0095 Backups, imports, exports | 0092 |
| 6 | 0096 Sync | 0095 |
| 7 | 0097 Hardware keys | 0091; the owner's YubiKey |
| 8 | 0098 Apple's side: passkeys, credential provider, Credential Exchange, iCloud | t49 (a team's signing), Apple's grant |
| 9 | 0099 Payments and the web's credential APIs | the screen with the owner; maybe t49 |

Not done: C; nothing is built.
