---
status: in-progress
blocked-by: 0092
date: 2026-11-19
---

# 0095 — Backups, imports and exports

Research: docs/research/credentials/backup-and-sync.md. ADR-0095 (proposed).

| Step | What | Status |
|---|---|---|
| A | `.svault` (renamed from `.sunsetvault` per owner, 2026-11-25): versioned, sealed, the key wrapped for the portable factors kept in backups (never Touch ID); a frozen v1 fixture test reads every version written | done 2026-11-25 (`VaultBackup`, `VaultBackup+Coding`, `VaultBackupTests`, `VaultBackupHostileTests`; 2,000-iteration fuzz, frozen v1 fixture, atomic `0600` writes) |
| B | Automatic backups to a chosen folder, keeping N; the emergency sheet (recovery code, QR) | done 2026-11-25 (`VaultBackupSchedule`, `PasswordsBackup`, `EmergencySheetView`; Settings `passwords.backupFolder` + `passwords.backupKeep` auto-backup at quit; Passwords "…" menu Back Up / Restore; Print Emergency Sheet on recovery code) — not yet seen on screen |
| C | KDBX 4 in and out (Argon2, ChaCha20 / AES, inner XML, attachments, history, `otp`); Sunset's types kept in a namespaced attribute | not-started |
| D | CSV in and out (Apple Passwords, Chrome, Firefox, Safari, Bitwarden, 1Password), out with a warning | in-progress: logins in, 2026-11-24 (`CSVReader` over CSVCoder's parser, `LoginImport`: Apple Passwords, Chrome / Edge / Brave, Firefox, Bitwarden, 1Password, LastPass, any file with a password column; the Passwords section's ellipsis menu, Import Logins from CSV…, with a confirmation, then the file left for the person to delete). CSV out, 2026-11-24 (`LoginExport`: Apple Passwords' columns, cells as kept with no apostrophe, only Login-template entries; the menu's Export Logins to CSV…: a warning, then the owner's word through Touch ID or the Mac's password, then a file only its owner can read). Not done: cards, notes and identities from a manager's export, an import that is one transaction and off the main thread |
| E | Bitwarden JSON (plain and protected), 1Password 1PUX | in-progress: Bitwarden's plain JSON in, 2026-11-24 (`LoginImport.readBitwarden` on AemiJSON; logins, secure notes, cards, identities; folders, favourites, notes, custom fields, every address; the trash and unknown kinds left out and said; an encrypted export refused with what to do). Not done: the password-protected export (PBKDF2 or Argon2id, then AES-256-CBC with HMAC: needs the crypto through a seam), 1PUX (a zip: no family package, Sunset's own inflater is in the core), export to Bitwarden |

Not done: C (KDBX 4, parked on AemiXML), E's protected Bitwarden export and 1PUX (parked on zip), CSV of cards and notes, and seeing the backup/restore/emergency-sheet UI on screen. Credential Exchange is 0098's.
