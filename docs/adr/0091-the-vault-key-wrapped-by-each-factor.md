---
status: proposed
date: 2026-11-19
---

# The vault key, wrapped by each unlock factor; locked means the key is gone

## Context

Lockable and backupable vaults (the owner, 2026-11-19). Probed (diary 2026-11-19-06): the Secure Enclave and Touch ID work
ad hoc signed; Aemi has Argon2. The app's storage key (`StorageKey`, the login Keychain) opens without the person, so it
cannot be what locks a vault.

## Decision (proposed)

- **The vault key:** 32 random bytes per vault; each purpose has its own derived key (HKDF), sealing as `Seal` does
  (ChaCha20-Poly1305).
- **Factors.** The vault key is wrapped once by each factor the person sets:
  - a master password (Argon2id, `AemiArgon2`, parameters set by measuring on the Mac: about 0.5–1 s);
  - this Mac's Secure Enclave under `.biometryCurrentSet` (Touch ID);
  - a recovery code (32 random bytes, shown once);
  - hardware keys (ADR-0097).
  - Any one opens the vault, or two if the person asks for two.
- **Locks:**
  - at quit;
  - after an idle time;
  - when the screen locks or the Mac sleeps;
  - when the last window of a profile using it closes;
  - by hand.
- **Locked means:**
  - the vault key and the decrypted index are dropped;
  - secrets live in locked, zeroed buffers, never strings until shown or filled;
  - the vault's windows are excluded from capture (`sharingType = .none`).
- **Shared with t48 D:** the master password's KDF and the recovery code's are one piece of work.

## Consequences

- Changing a factor rewraps one key; rotating the vault key reseals every record.
- A filled password is in WebKit's memory, beyond Sunset: said in Help, not hidden.

## Amended

By ADR-0104 (2026-11-19): every key exchange here is hybrid post-quantum (Secure Enclave P-256 and ML-KEM-1024; X-Wing HPKE between devices); symmetric hardware-key factors first.
