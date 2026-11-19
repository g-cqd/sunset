---
status: accepted
date: 2026-11-19
amends: ADR-0091, ADR-0095, ADR-0097 (proposed); t49's Secure Enclave wrap
---

# 0104 — Post-quantum by default: symmetric 256-bit keys, hybrid ML-KEM for every key exchange

## Context

The owner, 2026-11-19, wants post-quantum encryption everywhere around Sunset. The audit (docs/research/post-quantum-
2026-11-19.md, diary 2026-11-19-14) finds:
- everything Sunset seals today uses 256-bit symmetric keys, which hold;
- TLS already negotiates X25519MLKEM768;
- the exposure is in what was planned: Secure Enclave and hardware-key unlocks by elliptic-curve Diffie–Hellman, which a
  quantum attacker can open from a harvested vault file.

CryptoKit on this Mac has ML-KEM and ML-DSA in the Secure Enclave, and X-Wing HPKE, all usable ad hoc signed (probed).

## Decision

1. **Symmetric:** 256-bit keys only (ChaCha20-Poly1305 or AES-256-GCM; HKDF/HMAC with SHA-256 or stronger). No 128-bit
   keys.
2. **Key exchange:** never classical alone.
   - A key wrapped for a Secure Enclave (Touch ID, this Mac) uses both a P-256 ECDH key and an ML-KEM-1024 key there.
   - The wrap key is HKDF over both shared secrets and both ciphertexts or public keys, so it holds while either holds.
   - A key sent to another device uses X-Wing HPKE.
3. **Hardware keys:** factors that are symmetric (FIDO2 `hmac-secret` or PRF, HMAC challenge-response) come first. PIV
   ECDH is offered only beside another factor and says it is classical.
4. **Signatures,** when Sunset makes any (a device's sync log): ML-DSA-65.
5. **Tests:** every wrap has a test that fails if one half is dropped (removing the ML-KEM secret must change the wrap
   key).

## Consequences

- A Secure Enclave wrap is about 1 KB larger (ML-KEM's ciphertext); it is made once per factor.
- Passkeys, sites' certificates, Apple Pay and the Keychain's own internals stay classical: not Sunset's to change.
- The storage key moves to the data-protection keychain with its hybrid Secure Enclave wrap (task t121).
