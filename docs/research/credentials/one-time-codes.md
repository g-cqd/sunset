# One-time codes (2026-11-19)

## Algorithms

| Kind | Standard | Notes | Probed |
|---|---|---|---|
| HOTP | RFC 4226 | HMAC over an 8-byte counter, dynamic truncation, 6–8 digits (some issuers 9–10); the counter is stored and advanced on use | — |
| TOTP | RFC 6238 | HOTP with counter = ⌊(time − T0) / period⌋; SHA-1, SHA-256, SHA-512; period usually 30 s (60 s seen) | **Appendix B's 18 vectors pass** with CryptoKit's HMAC (SHA-1/256/512, 8 digits): `totp.swift` |
| Steam Guard | none (Valve) | TOTP SHA-1, 30 s, the 31-bit code written as five characters of `23456789BCDFGHJKMNPQRTVWXY` (least significant first) | The encoding runs (`PV9M4` from the SHA-1 vector at 59 s); not checked against a real Steam account |
| Yandex.Key | none (Yandex) | A PIN combined with the secret, SHA-256, 8 letters: documented only by reverse-engineering (andOTP, Aegis) | — |
| mOTP | none (2005) | MD5 of time/10, secret and PIN, 6 hex digits; legacy | — |
| Battle.net, Microsoft, Google, GitHub… | RFC 6238 | Plain TOTP (Battle.net: 8 digits) | — |

## Formats in

| Format | Where from | Notes |
|---|---|---|
| `otpauth://totp/Label?secret=…&issuer=…&algorithm=…&digits=…&period=…` and `otpauth://hotp/…&counter=…` | Google's "Key Uri Format" (google-authenticator wiki), every site's QR code | Base32 secret (any case, padding optional, spaces); the label is `Issuer:account`, URL-encoded; extra parameters seen: `image`, `color` (FreeOTP) — kept, unused |
| `otpauth-migration://offline?data=…` | Google Authenticator's export (one QR or a batch) | Base64 protobuf `MigrationPayload { repeated OtpParameters { secret bytes, name, issuer, algorithm, digits, type, counter } , version, batch_size, batch_index, batch_id }`; a small hand-written protobuf reader, no dependency |
| `steam://SECRET` | Steam Desktop Authenticator's maFiles, Aegis | The `shared_secret` (Base64) in an `.maFile` JSON |
| Aegis vault (JSON) | Aegis export | In the clear, or sealed: scrypt then AES-256-GCM per slot (the password), `db` sealed |
| 2FAS (`.2fas` JSON) | 2FAS export | In the clear, or PBKDF2-SHA256 then AES-GCM |
| andOTP JSON, FreeOTP+ JSON | the apps | In the clear, or (andOTP) PBKDF2 + AES-GCM |
| Bitwarden JSON, 1Password 1PUX, KeePass(XC) | password managers | Bitwarden: a `totp` field holding an otpauth URI or a bare secret; 1PUX: a field of type `otp`; KeePassXC: the `otp` attribute (otpauth), older KeePass plug-ins `TOTP Seed` / `TOTP Settings` |
| Apple Passwords CSV | the Passwords app's export | An `OTPAuth` column with an otpauth URI |
| Authy | — | No export: out of reach (said to the person) |

## QR codes

- **From an image file, the clipboard, or a region of the screen**: Vision's barcode detection (`VNDetectBarcodesRequest`,
  QR). A region of the screen needs the screen recording permission, so prefer a page's own image.
- **From the page itself**: Sunset is the browser. A site's set-up page shows the QR code in its own DOM, and Sunset can read
  the image from its own world (`WKContentWorld`) and offer "Add this code to an entry", the entry being the site's own
  login. Nothing is read from a page without the person's act.

## Using codes

- **Shown:** the current code, a countdown ring, and the next code near the end of the period.
- **Copied:** concealed, then cleared.
- **Filled** into `autocomplete="one-time-code"` fields, or the field after a password the site asks for, on the person's
  act (the fill engine's policy, [web-apis-and-payments.md](web-apis-and-payments.md)).
- **HOTP:**
  - the counter advances on each code shown;
  - sync merges counters by taking the highest;
  - a resync takes a code the person types and searches ahead in a window.
- **Clock:** TOTP uses the system's clock through the `Runtime` seam, so tests are deterministic (`TestTime`). A warning
  shows if the system clock is far from network time (`sntp` is not in reach of an app; use the `Date` header of the
  site's responses).
- **Codes kept on a hardware key** (YubiKey OATH, [hardware-keys.md](hardware-keys.md)) appear beside the vault's own, marked
  as such. The secret never leaves the key.

## Tests at implementation

RFC 4226 Appendix D, RFC 6238 Appendix B, the Key Uri Format's examples, a Google migration payload made by its app,
Aegis's and 2FAS's published test vaults: each a red test first.
