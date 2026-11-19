# Apple's side: Passwords, passkeys, the Keychain, Secure Enclave (2026-11-19)

Probed on this Mac (macOS 27.2.1, build 26B131) from ad hoc signed binaries, as Sunset is signed (`flags=0x2(adhoc)`,
`TeamIdentifier=not set`, read from the installed app). Diary 2026-11-19-06.

## Apple Passwords (iCloud Keychain) from a browser

| Path | What it gives | Verdict |
|---|---|---|
| Apple's helper for other browsers | Chrome's and Firefox's "iCloud Passwords" extension talks, by native messaging, to `/System/Cryptexes/App/System/Library/CoreServices/PasswordManagerBrowserExtensionHelper.app` (manifests in `/Library/Google/Chrome/NativeMessagingHosts/com.apple.passwordmanager.json`, allowed origins: two Chrome extension ids). The protocol (pairing by a PIN the system shows, then SRP-sealed messages) is in Apple's extension; `bendews/apw` (read 2026-11-19) now runs Apple's extension inside a headless Chromium to reach it | **Closed to Sunset (probed).** Launched by any other program, the kernel kills it: `AMFI: Launch Constraint Violation (enforcing) … (Constraint not matched)`. Its entitlements are Apple-private (`com.apple.private.keychain.kcsharing.client`, `com.apple.private.safari.automatic-password-change`…) |
| `ASAuthorizationPasswordProvider` | The Keychain's passwords for the app's own associated domains | Not for any site: no |
| `ASAuthorizationWebBrowserPublicKeyCredentialManager` (macOS 13.3) and `ASAuthorizationPlatformPublicKeyCredentialProvider` with `ASPublicKeyCredentialClientData` (13.5) | **Passkeys** for any relying party: iCloud Keychain's and third-party providers' (`platformCredentials(forRelyingParty:)`, an authorisation the person grants); registration and assertion; security keys through `ASAuthorizationSecurityKeyPublicKeyCredentialProvider` (12.0) | Yes, with `com.apple.developer.web-browser.public-key-credential`: requested by the team's Account Holder on Apple's form, reviewed against browser criteria (http and https schemes, an address field on launch, navigates where asked), granted as a managed capability (read). Needs t49 |
| Credential Exchange: `ASCredentialImportManager`, `ASCredentialExportManager` (macOS 26) | The person moves passwords and passkeys from Apple Passwords (or any provider) into another, through a system sheet, never a file; FIDO's credential exchange format, version 1.0 | Yes, once Sunset is a credential provider (below): the clean import from Passwords. Needs t49 |
| The Passwords app's export (File › Export, CSV) | Title, URL, username, password, notes, OTP auth (a CSV file in the clear) | Yes, now. The file is the person's to delete; Sunset says so |
| System AutoFill in Sunset's web views | Whether macOS offers Apple Passwords' suggestions in a third-party app's `WKWebView` form | **Unprobed**: needs the screen. AppKit's `NSTextContentType` (11.0) is for native fields |

## Sunset's vault for Safari and other apps

`ASCredentialProviderViewController` (macOS 11.0) in an app extension, with
`com.apple.developer.authentication-services.autofill-credential-provider` (read):
- passwords from macOS 11;
- passkeys from 14 (`ASCredentialProviderExtensionCapabilities`);
- one-time codes from 15 (`ASOneTimeCodeCredential`, `ASCredentialRequestType.oneTimeCode`).

The extension lists what it has through `ASCredentialIdentityStore` (identities only, no secrets). The person turns it on in
System Settings › Passwords. It must open the vault itself, so the vault's unlock works from the extension's process too.
Needs t49, and Apple's supported-capabilities table for Developer ID (its marks are images, unread: to check in the
owner's account).

## The Keychain

| Item | Probed |
|---|---|
| The file-based login keychain (Sunset's storage key today, `KeychainKeyVault`) | Works ad hoc: `SecItemAdd` 0 |
| The data-protection keychain (`kSecUseDataProtectionKeychain`) | −34018 "A required entitlement is not present": needs a team (`keychain-access-groups`) |
| iCloud Keychain (`kSecAttrSynchronizable`) | −34018: same |

## Secure Enclave, Touch ID

| Item | Probed |
|---|---|
| `SecureEnclave.isAvailable` | true |
| A P-256 key agreement key in the Secure Enclave, ad hoc signed | Made, its 284-byte wrapped blob kept and restored, ECDH equal both ways |
| The same with `.privateKeyUsage, .biometryCurrentSet` access control | Made (using it asks Touch ID: not exercised, needs the person) |
| `LAContext` | Touch ID (`biometryType` 1) available; owner authentication available |

So the vault can be unlocked by Touch ID now. The vault key is wrapped by a key derived from ECDH with a Secure Enclave
key; that key needs biometry and is this Mac's only (`.biometryCurrentSet`: a new finger enrolled invalidates it; the
password or recovery code then reopens). t49's "Secure Enclave wrapping" of the storage key is the same move, and also
works ad hoc.

## What a team's signing (t49) unlocks, in one list

- Passkeys and security keys for any site (with Apple's grant).
- The credential provider extension: Sunset's vault in Safari, apps, and Passwords' Credential Exchange.
- The data-protection keychain and iCloud Keychain (the vault key across the person's Macs).
- CloudKit and iCloud Drive containers.
- Maybe Apple Pay's sheet (open: [web-apis-and-payments.md](web-apis-and-payments.md)).
- Library validation and the hardened runtime (0051 F).
