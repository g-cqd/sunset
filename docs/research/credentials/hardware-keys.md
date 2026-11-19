# Hardware keys: YubiKey and others (2026-11-19)

No key was attached during this research (`system_profiler`, `ioreg`: none; CryptoTokenKit with the smart card entitlement:
`slotNames == []`), so nothing here was tried against a key. What a YubiKey 5 offers, from Yubico's documentation (recalled,
to read again at implementation): FIDO2/WebAuthn (CTAP2.1), FIDO U2F, PIV (smart card), OpenPGP, OATH (TOTP/HOTP codes held
on the key), and Yubico OTP with two slots, one of which may hold an HMAC-SHA1 challenge-response secret.

## On the web: security keys for sites

| Path | Verdict |
|---|---|
| WebKit's own WebAuthn in Sunset's views | Refused without the browser entitlement: `navigator.credentials.create` answered `NotAllowedError … not allowed by the user agent or the platform` in 12 ms from a real click in a focused window, no sheet (probed, `webauthn-click.swift`). `PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()` is false |
| `ASAuthorizationSecurityKeyPublicKeyCredentialProvider` (macOS 12) through Sunset's own `navigator.credentials` | With `com.apple.developer.web-browser.public-key-credential` (after t49 and Apple's grant): the system's sheet handles USB and NFC keys; Sunset relays the page's request with the frame's origin from `WKFrameInfo`, never from the page. Whether WebKit's own path then works by itself, with the entitlement, is to probe then |
| Sunset's own CTAP2 over USB HID (FIDO usage page `0xF1D0`) | Possible without Apple (Chrome did its own CTAP before macOS gave browsers the system path): CBOR, the PIN protocol, every extension. Large, and a second WebAuthn to keep in step with the standard: only if Apple refuses the entitlement |

## Unlocking the vault with a key

| Way | How | Needs | Verdict |
|---|---|---|---|
| FIDO2 `hmac-secret` / WebAuthn PRF | The key computes HMAC(a secret it keeps for one credential, a salt Sunset keeps): the output wraps the vault key. Touch of the key, and its PIN if set | Through the system: `ASAuthorizationPublicKeyCredentialPRFAssertionInput` (macOS 15) needs an RP id Sunset may use (the browser entitlement or an associated domain: t49). Through Sunset's own CTAP2 over HID: no Apple entitlement; access to a FIDO HID device from an unsandboxed app is to probe with a key | The best factor (phishing-proof, per-credential) |
| PIV (smart card) | ECDH with the key's slot 9D (key management) P-256 private key: the shared secret wraps the vault key. The key's PIN, maybe a touch | CryptoTokenKit (`TKSmartCard`, APDUs) with `com.apple.security.smartcard`, which ad hoc signing carries (probed: the slot manager answers with it, is nil without) | Feasible now; also works with any PIV card |
| HMAC-SHA1 challenge-response (OTP slot 2) | KeePassXC's way: Sunset sends a challenge, the key answers HMAC-SHA1(its slot secret, challenge) | USB HID feature reports on the key's OTP interface, which is keyboard-class: whether macOS asks for Input Monitoring for it is to probe | Feasible if HID access is plain; compatible with KeePassXC vaults |
| OpenPGP | Decrypt with the key's encryption subkey | CCID through CryptoTokenKit | Possible, no reason to prefer it over PIV |

Several keys may be enrolled: a factor per key, any one opening the vault, so a spare key in a drawer is the person's backup.

## Codes kept on the key (OATH)

The key's OATH application (YKOATH over CCID: `SELECT`, `LIST`, `CALCULATE`, `CALCULATE ALL`) holds TOTP/HOTP secrets
that never leave it. Through CryptoTokenKit, Sunset can list and compute them: they would show and fill beside the vault's
own, marked "on your YubiKey", with a touch when the key requires one. Adding a code to the key from a QR code
(`PUT`) is possible too.

## To probe with a key (the owner's)

1. `TKSmartCardSlotManager.default.slotNames` lists it; `SELECT` PIV and OATH answer.
2. A FIDO HID device appears to `IOHIDManager` (usage page 0xF1D0) from an unsandboxed ad hoc app, without a permission sheet.
3. The OTP interface's feature reports are readable without Input Monitoring.
4. With t49: the system sheet's security key path from Sunset's relay, and PRF on a key.
