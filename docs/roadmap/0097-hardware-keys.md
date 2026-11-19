---
status: not-started
blocked-by: 0091; the owner's YubiKey to probe with
date: 2026-11-19
---

# 0097 — Hardware keys: YubiKey and others

Research: docs/research/credentials/hardware-keys.md. ADR-0097 (proposed). No key was attached during the research.

| Step | What | Status |
|---|---|---|
| A | Probes with the owner's key: CryptoTokenKit slot, PIV and OATH `SELECT`; a FIDO HID device seen by `IOHIDManager`; the OTP interface's feature reports without Input Monitoring | not-started |
| B | PIV as an unlock factor (ECDH, slot 9D, PIN); several keys enrolled | not-started |
| C | OATH: codes on the key listed, shown, filled; adding one from a QR code | not-started |
| D | FIDO2 `hmac-secret` as an unlock factor (Sunset's CTAP2 over HID if A allows; PRF through the system after t49) | not-started |
| E | HMAC-SHA1 challenge-response (KeePassXC compatible) if A allows | not-started |

Not done: everything.
