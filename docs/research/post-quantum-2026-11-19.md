# Post-quantum: what Sunset uses, what it will use (2026-11-19)

The owner, 2026-11-19: "i really want that we make sure to use post-quantum safe algorithm for our encryption and that
everything is safe around sunset". Probes: `docs/research/probes/post-quantum/main.swift` (diary 2026-11-19-14), run ad hoc
signed on macOS 27.2.1.

## The threat

A cryptographically relevant quantum computer breaks the public-key algorithms used today:
- Shor's algorithm breaks RSA, the elliptic curves (P-256, X25519), and Diffie–Hellman on them.
- Grover's algorithm only halves a symmetric key's or a hash's strength: a 256-bit key keeps about 128 bits.

The danger now is **harvest now, decrypt later**: what is kept or sent today encrypted under a key exchange can be opened
once such a machine exists. Signatures only matter at the moment they are checked.

## What Sunset uses today

| Where | Algorithm | Quantum-safe? |
|---|---|---|
| The storage key (`StorageKey`) | 256 random bits (`SymmetricKey(size: .bits256)`) | Yes (≈128 bits against Grover) |
| Sealing (`Seal`: state, sessions, documents, cookie jars) | ChaCha20-Poly1305, a key per purpose from HKDF-SHA256 | Yes |
| Record names (`SealedTable`) | HMAC-SHA256 with a secret key, cut to 16 bytes | Yes: without the key nothing can be computed |
| Kept commands (`CommandSeal`) | HMAC-SHA256, 256-bit key | Yes |
| The recovery code's check | SHA-256, two characters | Not a security measure (a typo check) |
| Where the storage key is kept | The file-based login Keychain | Apple's encryption of that keychain, keyed by the login password: not measured here. The data-protection keychain (Secure Enclave–backed class keys) is now possible (`keychain-access-groups` granted with the Developer ID profile): to move to (task t121) |
| TLS for pages and Sunset's own fetches | WebKit's and URLSession's | **Hybrid post-quantum already**: `kex=X25519MLKEM768` over TLS 1.3, HTTP/2 (URLSession) and HTTP/3 (a page), to Cloudflare. The certificates' signatures stay classical; they only matter when checked |

## What CryptoKit has on this Mac (probed)

| Primitive | Result |
|---|---|
| ML-KEM-768 in the Secure Enclave | Made, its wrapped blob (1,449 B) restored, encapsulation (1,088 B) opened to the same secret |
| ML-KEM-1024 in the Secure Enclave under `.biometryCurrentSet` | Made (2,118 B blob); opening it asks Touch ID, not exercised |
| X-Wing (ML-KEM-768 + X25519) HPKE, AES-256-GCM | A 32-byte key sealed and opened; encapsulation 1,120 B |
| ML-DSA-65 in the Secure Enclave | A signature (3,309 B) made and checked |

## What the plans used, and what they become

| Planned (ADR) | As proposed | Becomes (ADR-0104) |
|---|---|---|
| Touch ID unlock of a vault (ADR-0091) | ECDH with a Secure Enclave P-256 key | Hybrid: P-256 ECDH **and** ML-KEM-1024 decapsulation, both by Secure Enclave keys under biometry; the vault key wrapped by HKDF over both secrets and both ciphertexts |
| A vault key for another device (ADR-0095: a new Mac joining) | Not specified | X-Wing HPKE to the device's key |
| The storage key's Secure Enclave wrap (t49) | ECDH with a Secure Enclave key | The same hybrid as Touch ID |
| Hardware keys (ADR-0097) | PIV ECDH first, FIDO2 `hmac-secret` second | `hmac-secret` / PRF and OTP HMAC challenge-response first: symmetric, quantum-safe. PIV only beside another factor, and marked "classical" |
| Master password, recovery code (ADR-0091) | Argon2id; random 256 bits | Unchanged: symmetric |
| Sync and backups (ADR-0095) | Records sealed by the vault key | Unchanged: symmetric. If a device's log ever needs signing, ML-DSA-65 |

## What stays outside Sunset's hands

- Passkeys and WebAuthn signatures (P-256): the sites' and the platform's.
- Apple Pay and the Keychain's own internals.
- Sites' certificates.
