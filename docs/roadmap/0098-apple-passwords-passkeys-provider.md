---
status: blocked
blocked-by: t49 (a team's signing); Apple's grant of the browser entitlement
date: 2026-11-19
---

# 0098 — Apple's side: passkeys, the credential provider, Credential Exchange, iCloud

Research: docs/research/credentials/apple-platform.md. ADR-0098 (proposed).

| Step | What | Status |
|---|---|---|
| A | Now: the Passwords app's CSV import (through 0095 D), with the reminder to delete the file | not-started |
| B | With the owner on screen: whether macOS offers Apple Passwords' AutoFill in Sunset's web views by itself | not-started |
| C | After t49: request `com.apple.developer.web-browser.public-key-credential`; Developer ID's capabilities read in the owner's account | blocked |
| D | Passkeys and security keys in pages: Sunset's `navigator.credentials` (shaped as WebKit's) relayed to `ASAuthorizationController`, origin from `WKFrameInfo`; conditional mediation in Sunset's suggestions | blocked |
| E | The credential provider extension (passwords, passkeys, codes) opening the vault itself; Credential Exchange in and out | blocked |
| F | iCloud Keychain for the vault key (0096 F) | blocked |

Not done: everything.
