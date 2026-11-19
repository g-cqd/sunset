---
status: not-started
blocked-by: 0092
date: 2026-11-19
---

# 0095 — Backups, imports and exports

Research: docs/research/credentials/backup-and-sync.md. ADR-0095 (proposed).

| Step | What | Status |
|---|---|---|
| A | `.sunsetvault`: versioned, sealed, the key wrapped for the factors kept in backups; a test reads every version written | not-started |
| B | Automatic backups to a chosen folder, keeping N; the emergency sheet (recovery code, QR) | not-started |
| C | KDBX 4 in and out (Argon2, ChaCha20 / AES, inner XML, attachments, history, `otp`); Sunset's types kept in a namespaced attribute | not-started |
| D | CSV in and out (Apple Passwords, Chrome, Firefox, Safari, Bitwarden, 1Password), out with a warning | not-started |
| E | Bitwarden JSON (plain and protected), 1Password 1PUX | not-started |

Not done: everything. Credential Exchange is 0098's.
