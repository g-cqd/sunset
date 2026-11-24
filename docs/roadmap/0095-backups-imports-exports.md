---
status: in-progress
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
| D | CSV in and out (Apple Passwords, Chrome, Firefox, Safari, Bitwarden, 1Password), out with a warning | in-progress: logins in, 2026-11-24 (`CSVReader` over CSVCoder's parser, `LoginImport`: Apple Passwords, Chrome / Edge / Brave, Firefox, Bitwarden, 1Password, LastPass, any file with a password column; the Passwords section's ellipsis menu, Import Logins from CSV…, with a confirmation, then the file left for the person to delete). CSV out, 2026-11-24 (`LoginExport`: Apple Passwords' columns, cells as kept with no apostrophe, only Login-template entries; the menu's Export Logins to CSV…: a warning, then the owner's word through Touch ID or the Mac's password, then a file only its owner can read). Not done: cards, notes and identities from a manager's export, an import that is one transaction and off the main thread |
| E | Bitwarden JSON (plain and protected), 1Password 1PUX | not-started |

Not done: A, B, C, E, D's export side. Credential Exchange is 0098's.
