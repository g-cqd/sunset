# Credentials, passwords, hardware keys and payments — research (2026-11-19)

The owner, 2026-11-19: "go over the security topic and then investigate security topics and the interfaces and apis related
to security, payment, and password handling. i'd like that sunset supports native apple passwords but also build its own
password management scope (toggleable as a feature scope), backupable, lockable … local storage or sync through icloud or
other providers, and also support for things such as yubikeys … entries in the database that you could customize the content
and layout of, add or remove fields, with various types and constraints, attaching notes and files and have working totp
supporting many format and standards. please stage the tasks and the roadmap and the adrs".

Claims until probed (AGENTS.md). What was probed is in diary 2026-11-19-06, the probes in `docs/research/probes/credentials/`;
everything else here is read (Apple's documentation, the standards) or recalled, and says so.

| File | What |
|---|---|
| [apple-platform.md](apple-platform.md) | Apple Passwords, passkeys, the credential provider, Credential Exchange, the Keychain, Secure Enclave, Touch ID; what needs signing |
| [vault.md](vault.md) | Sunset's own vault: the scope, the store, the keys, locking; entries, templates, fields, constraints, layout, notes, files |
| [one-time-codes.md](one-time-codes.md) | HOTP, TOTP, Steam and the others; the URI and export formats; QR codes |
| [backup-and-sync.md](backup-and-sync.md) | Backups, imports, exports; sync through a folder, iCloud, other providers; merging |
| [hardware-keys.md](hardware-keys.md) | YubiKey and other keys: on the web, and to unlock the vault (FIDO2, PIV, OATH, OTP) |
| [web-apis-and-payments.md](web-apis-and-payments.md) | The web's credential, security and payment APIs against Safari; Apple Pay; filling and saving in pages |

## The security topic as it stands (open before this research)

| Task | What | State |
|---|---|---|
| t48 | 0051 C–E: less in clear (times, counts, kinds, row keys by HMAC), the recovery code's KDF (Argon2id — `AemiArgon2` exists in Aemi, unused by Sunset), sealed exports | not started; stage 2 of roadmap 0058 |
| t51, t59 | 0051 I: WebKit's own stores sealed (an encrypted image), measured before a decision | t51 not started; t59 in progress |
| t49 | 0051 F: Developer ID, hardened runtime, library validation, Secure Enclave wrapping | blocked on the owner's certificate |
| — | White paper §9: what an untrusted page can ask has a policy and a test | held for notifications, share, sign-in watch (ADR-0089) |

## What this research changes

**t49 is the gate for everything Apple holds.** Measured: Sunset is ad hoc signed (no team). Refused or impossible without a
team's signing and a provisioning profile:
- passkeys for any site, which need `com.apple.developer.web-browser.public-key-credential`, granted by Apple on request to
  an Account Holder;
- the data-protection keychain and iCloud Keychain (−34018, probed);
- iCloud (CloudKit, iCloud Drive containers);
- the AutoFill credential provider;
- Credential Exchange.

It is no longer only about hardening.

**Free now, with no signing:**
- the Secure Enclave and Touch ID (probed: a key gated by biometry is made ad hoc signed);
- CryptoKit;
- `AemiArgon2`;
- smart cards through CryptoTokenKit (probed with `com.apple.security.smartcard`, an entitlement ad hoc signing carries);
- a synced folder;
- HTTP providers.

The whole vault, one-time codes, backups, folder sync, KDBX and PIV/OATH keys can be built before t49.

**Apple Passwords' passwords are out of reach for a browser on macOS.**
- Apple's helper for Chrome's iCloud Passwords extension is killed by the kernel when another program launches it
  (AMFI "Launch Constraint Violation", probed).
- No public API reads them for any site.
- The ways in: Credential Exchange (macOS 26+, Sunset as a credential provider: after t49), the Passwords app's CSV export
  (now), and system AutoFill in a web view (unprobed: needs the screen).

## Feasibility at a glance

| Want | Feasible | Needs | Effort |
|---|---|---|---|
| Own vault, lockable (password, Touch ID, recovery code) | yes | nothing new | large |
| Entries: templates, typed fields, constraints, layout, notes, files, history | yes | nothing new | large |
| TOTP / HOTP / Steam, otpauth and Google migration imports, QR from a page | yes (RFC 6238 vectors pass with CryptoKit, probed) | nothing | medium |
| Backups and KDBX / CSV / Bitwarden / 1Password / Aegis / 2FAS imports | yes | format work | medium each |
| Sync through any synced folder (iCloud Drive, Dropbox, Syncthing) | yes | a merge design | medium |
| Sync through WebDAV, S3, Dropbox / Google Drive / OneDrive APIs | yes | OAuth (ASWebAuthenticationSession) | medium each |
| Sync through CloudKit; the vault key through iCloud Keychain | after t49 | iCloud entitlement, provisioning | medium |
| Passkeys and security keys on sites (iCloud Keychain, third-party providers) | after t49 and Apple's grant | the browser entitlement | large |
| Sunset's vault in Safari and other apps (credential provider) | after t49 | an app extension, entitlement | large |
| Import from Apple Passwords | CSV now; Credential Exchange after t49 | — | small / medium |
| YubiKey PIV (unlock) and OATH (codes on the key) | yes (CryptoTokenKit) | a key to test with | medium |
| YubiKey FIDO2 hmac-secret (unlock) | yes, by Sunset's own CTAP2 over HID; or PRF after t49 | a key; CBOR and CTAP2 | large |
| YubiKey OTP HMAC challenge-response (unlock, KeePassXC's way) | likely | a key; a probe of HID access | medium |
| Apple Pay and Payment Request in pages | open: begins, the sheet's extension starts, then cancels (probed) | the screen; maybe signing | unknown |
| Card, address, one-time-code filling from the vault | yes | the fill engine | medium |
