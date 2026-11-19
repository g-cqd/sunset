---
status: proposed
date: 2026-11-19
---

# Apple Pay and Payment Request stay off until seen working

## Context

Safari has `ApplePaySession`, `PaymentRequest` and `DigitalCredential`; Sunset has none (inventory, t98). One WebKit flag,
`ApplePayEnabled`, brings the first two. With it on, a click's `begin()` launches PassKit's payment sheet extension, then the
session is cancelled without merchant validation, with or without a user script. WebKit's 2019 rule (no Apple Pay after
script injection) was not reproduced at that step; the reason for the cancel is unread (diary 2026-11-19-06).

## Decision (proposed)

- `ApplePayEnabled` stays off until the sheet is seen to work on screen with the owner, on Apple's demo merchant, signed as
  Sunset is shipped then. A page offering Apple Pay that always cancels is worse than one that offers another way.
- `DigitalCredentialsEnabled` stays off until probed alike.
- Cards are filled from the vault instead (ADR-0094); the security code is never filled without a reveal.

## Consequences

- Until then a page tells Sunset from Safari by these interfaces (t98).
- Sites using Apple's JS SDK may show their QR code flow for browsers without Apple Pay: to check on a real shop.
