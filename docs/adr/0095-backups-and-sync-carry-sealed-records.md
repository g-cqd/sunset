---
status: accepted
date: 2026-11-20
---

# Backups and sync carry sealed records; each device writes only its own log

## Context

Backups, local storage, "sync through icloud or other providers" (the owner, 2026-11-19). A dumb file sync (iCloud Drive,
Dropbox, Syncthing) makes conflicted copies when two machines write one file. iCloud Drive's folder needs no entitlement;
CloudKit and iCloud Keychain need t49 (probed −34018).

## Decision (proposed)

- **Nothing leaves Sunset unsealed:** every record is sealed with the vault key, whatever the provider.
- **The sync layout:** each device appends sealed segments to a log of its own, in a folder all devices read. No file has
  two writers. Each log is compacted by its own device once the others have read past it.
- **Merge:**
  - by record, then by field, through a hybrid logical clock (the later write wins; the earlier goes into history);
  - tombstones are kept until every device has seen them;
  - notes edited on two devices at once keep both;
  - HOTP counters take the highest.
  - A pure function, tested against offline devices and wrong clocks.
- **Providers:** behind one seam. The folder first (iCloud Drive's included). WebDAV, S3, the Dropbox / Google Drive /
  OneDrive APIs, Git next. CloudKit, and the vault key through iCloud Keychain, after t49.
- **Backups:** one versioned file (`.sunsetvault`) holding the records and the vault key wrapped for the factors the person
  keeps in backups. Never the Secure Enclave's wrap, which another Mac cannot open.
- **Interchange:** KDBX 4 in and out. CSV in and out with a warning. Bitwarden, 1Password, Aegis, 2FAS and Google
  Authenticator in. FIDO's credential exchange through the system after t49.

## Consequences

- A second Mac joins with the master password or the recovery code, then wraps the key for its own Secure Enclave.
- The merge rules and every format reader are red-first tests with published vectors where they exist.

## Amended

By ADR-0104 (2026-11-19): every key exchange here is hybrid post-quantum (Secure Enclave P-256 and ML-KEM-1024; X-Wing HPKE between devices); symmetric hardware-key factors first.

By the KeePass import (2026-11-28): KDBX 4 is read in (`LoginImport.readKeePass`): AES-256 or ChaCha20, AES-KDF or
Argon2d/id (version 1.3, its cost bounded before deriving), gzip, a password and an optional key file (XML 1.0/2.0, 32
raw bytes, 64 hex digits, else its SHA-256). Entries become logins or secure notes with their custom fields (protected ones
hidden), group path as folder, tags, attachments up to 4 MiB, one-time codes and their password's history; the recycle
bin's are left out. Checked against databases pykeepass wrote. KDBX 3 is refused (saved again by KeePass, it is 4); KDBX
out is not built.

By the 1Password import (2026-11-28): `.1pux` is read in (`LoginImport.readOnePassword`), its zip read in memory (stored or
DEFLATE members, each checked by its CRC-32; Zip64 and encrypted members refused; what inflates bounded). Logins and
passwords, cards, identities, secure notes, documents and SSH keys become entries of their template, any other category a
secure note with every field kept; section fields fill the template's fields where 1Password's ids match, else fields of
their own of the value's kind; the one-time code, the password's history, tags, favourites, files, and the vault as the
folder when there are several. Archived items are left out. Checked against an export written to 1Password's documented
format, not one 1Password wrote.

