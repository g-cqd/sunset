---
status: not-started
blocked-by: 0092
date: 2026-11-19
---

# 0093 — One-time codes: HOTP, TOTP, Steam and the others

Research: docs/research/credentials/one-time-codes.md. Probed: RFC 6238's vectors pass with CryptoKit (diary 2026-11-19-06).

| Step | What | Status |
|---|---|---|
| A | HOTP (RFC 4226), TOTP (RFC 6238; SHA-1/256/512, 6–10 digits, any period), Steam; red tests from the RFCs' appendices | not-started |
| B | `otpauth://` (Key Uri Format, its variants), `otpauth-migration://` (Google Authenticator's protobuf, batches), `steam://` and maFiles | not-started |
| C | Imports: Aegis (plain, scrypt-sealed), 2FAS, andOTP, FreeOTP+; from Bitwarden / 1Password / KeePassXC / Apple Passwords CSV through 0095 | not-started |
| D | QR codes: an image, the clipboard, the page's own image (from Sunset's world, on the person's act) | not-started |
| E | Showing (countdown, next code), copying (concealed, cleared), filling `one-time-code` fields; HOTP resync | not-started |
| F | Yandex.Key and mOTP, only if the owner wants them (reverse-engineered, legacy) | not-started |

Not done: everything.
