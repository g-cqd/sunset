---
status: proposed
date: 2026-11-19
---

# Hardware keys unlock a vault and hold codes; the web's security keys come with the system's path

## Context

"support for things such as yubikeys" (the owner, 2026-11-19). Probed: smart cards answer through CryptoTokenKit with an
entitlement ad hoc signing carries; WebKit's WebAuthn is refused without the browser entitlement; no key was attached, so
nothing was tried against one (docs/research/credentials/hardware-keys.md).

## Decision (proposed)

- **Unlock factors**, in this order:
  1. PIV (ECDH with slot 9D, through CryptoTokenKit): now;
  2. FIDO2 `hmac-secret` / PRF: through the system after t49, or Sunset's own CTAP2 over HID if a probe with a key shows
     HID access is plain;
  3. HMAC-SHA1 challenge-response (KeePassXC's way), for KeePassXC compatibility, after a probe of its HID interface.
  - Several keys may be enrolled; any one opens the vault.
- **Codes kept on the key** (OATH over CCID): listed and filled beside the vault's own, marked; the secret never leaves the
  key.
- **On the web:** security keys and passkeys through `ASAuthorization` with the browser entitlement (ADR-0098). Sunset does
  not write its own CTAP2 for the web unless Apple refuses the entitlement.

## Consequences

Nothing on this list is done without a red test run against the owner's key: each step is blocked on one.
