---
status: accepted
date: 2026-11-20
---

# Apple Passwords through its public paths only

## Context

"sunset supports native apple passwords" (the owner, 2026-11-19). Probed (diary 2026-11-19-06):
- Apple's helper for Chrome's iCloud Passwords extension is killed by the kernel when another program launches it (AMFI
  launch constraint);
- WebKit's WebAuthn is refused without the browser entitlement;
- the data-protection and iCloud keychains are refused without a team (−34018).

Read: passkeys for any site need `com.apple.developer.web-browser.public-key-credential`, granted by Apple on request
(macOS 13.3); Credential Exchange (macOS 26) and the AutoFill credential provider (macOS 11; passkeys 14; codes 15) need an
app extension and its entitlement.

## Decision (proposed)

- **No private path** to Apple Passwords: no helper, no private entitlement, no reading of the Keychain's files.
- **Now:** importing the Passwords app's CSV export, with a reminder to delete the file.
- **After t49** (a team's signing):
  1. request the browser entitlement; passkeys and security keys in pages through `ASAuthorizationController`, relayed by
     Sunset's own `navigator.credentials` (shaped as WebKit's, ADR-0089);
  2. a credential provider extension: Sunset's vault in Safari and other apps, and Credential Exchange from Apple Passwords
     into Sunset;
  3. iCloud Keychain for the vault key, and CloudKit sync.
- **Probe with the owner on screen:** whether macOS offers Apple Passwords' AutoFill in Sunset's web views by itself.

## Consequences

- Without t49, "Apple Passwords" means a one-way CSV import: said plainly in Settings and Help.
- t49 is now the gate for this whole scope, not only for hardening.
