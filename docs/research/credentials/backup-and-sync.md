# Backups, imports, exports and sync (2026-11-19)

## Backups

- **Sunset's own backup:** one file, `.sunsetvault`:
  - a header: magic, version, the vault id, the wrapped vault key for each factor kept in backups (the person picks:
    master password and recovery code by default; never this Mac's Secure Enclave, which another Mac cannot open);
  - then every record sealed as in the vault, attachments included.
  - Restoring opens it with any of those factors.
  - The format is versioned from the first byte. A test reads every version ever written (as Sunset's settings migrations
    do).
- **Automatic:** to a folder the person picks (an external disk, a synced folder), at quit or daily, keeping the last N.
  Time Machine also backs up the vault's own file, sealed.
- **The emergency sheet:** a printable page with the vault's name, the recovery code and a QR code of it. It is made on
  request and shown once, as the storage key's recovery code is today.

## Imports and exports

| Format | In | Out | Notes |
|---|---|---|---|
| KeePass KDBX 4.x | yes | yes | The open interchange: Argon2d/Argon2id (`AemiArgon2`) or AES-KDF, ChaCha20 or AES-256-CBC, HMAC-SHA-256 blocks, an inner XML with custom strings, attachments, history, the `otp` attribute (keepass.info's KDBX 4 notes, read before; to read again at implementation). Custom fields map to strings; types beyond strings go in a namespaced attribute so that a round trip through Sunset keeps them |
| CSV (Apple Passwords, Chrome, Firefox, Safari, Bitwarden, 1Password) | yes | yes, with a warning | Columns detected by header; in the clear by nature. The file is deleted only by the person |
| Bitwarden JSON (plain and password-protected) | yes | — | Password-protected: PBKDF2-SHA256 or Argon2id, then AES-256-CBC + HMAC |
| 1Password 1PUX | yes | — | A zip with `export.data` (JSON) and files |
| Aegis, 2FAS, andOTP, Google Authenticator | yes (codes) | — | [one-time-codes.md](one-time-codes.md) |
| FIDO Credential Exchange (CXF 1.0) | via the system, after t49 | via the system, after t49 | `ASCredentialImportManager` / `ExportManager` (macOS 26): the format is the system's to carry; Sunset maps its fields |
| Sunset's backup | yes | yes | Above |

## Sync

Each record is sealed by the vault key before it leaves Sunset, whatever the provider, so a provider stores bytes it cannot
read. The provider's own encryption is a second layer, never the only one.

**The layout: each device writes only its own.** A device appends to a log of its own: segment files of sealed records,
named `<device>/<sequence>`. Every device reads all the logs and merges them.
- Two devices never write the same file, so a dumb file sync (iCloud Drive, Dropbox, OneDrive, Syncthing, a USB stick) has
  nothing to conflict over: no "conflicted copy" files.
- A log is compacted by its own device once the others have read past a point. Each device publishes how far it has read.

**Merging:**
- by record id;
- each field by its hybrid logical clock (time and counter, plus the device): the later write wins, the earlier is kept in
  the entry's history;
- a deletion is a tombstone, kept until every device has seen it;
- notes edited on two devices at once keep both versions and ask the person;
- a HOTP counter takes the highest.

The rules are a pure function under tests (two, three, offline devices, clocks wrong by hours).

**A new device:**
- reads the folder;
- asks for the master password or the recovery code to unwrap the vault key from the shared header;
- then wraps it for its own Secure Enclave.

**Providers**, behind one seam (list, read, write if absent, delete):

| Provider | Needs | Verdict |
|---|---|---|
| A folder: any synced folder, including iCloud Drive's (`~/Library/Mobile Documents/com~apple~CloudDocs/…`) | Nothing: a path the person picks (an unsandboxed app may write there; iCloud Drive syncs it) | First. Works now |
| WebDAV (Nextcloud, ownCloud, Synology) | HTTP | Small |
| S3-compatible (AWS, R2, Backblaze, MinIO) | SigV4 signing (CryptoKit HMAC) | Small |
| Dropbox, Google Drive, OneDrive APIs | OAuth through `ASWebAuthenticationSession`; each vendor's app registration | Medium each; the folder path covers their desktop clients already |
| A Git repository | Sunset's own Git client, or the `git` binary through `AemiProcess` | Medium; good for people who want history |
| CloudKit (the person's private database) | The iCloud capability, a provisioning profile: t49 | After t49 |
| iCloud Keychain for the vault key alone (so a second Mac opens without the recovery code) | The data-protection keychain: t49 (−34018, probed) | After t49 |

## Measures before done

- Sync of 10,000 entries in, merge time out (release, percentiles).
- A segment's size against the count of files a synced folder copes with.
- Compaction time.
