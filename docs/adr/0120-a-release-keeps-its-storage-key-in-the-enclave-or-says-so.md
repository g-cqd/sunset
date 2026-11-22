---
status: accepted
date: 2026-11-22
---

# A release keeps its storage key wrapped by the Secure Enclave, or says it cannot

## Context

The key that seals what Sunset keeps moved from the login Keychain to the data-protection keychain, wrapped by the Secure
Enclave (`MovingKeyVault`, `EnclaveKeyVault`). When the new place failed, it fell back to the login Keychain silently: needed
by ad-hoc builds, which lack the team's entitlement. The outside audit of 2026-11-22 (HIGH-03) found a release would fall
back the same way. The owner chose (2026-11-22): a release refuses; a development build falls back.

## Decision

- A team-signed build that is not a development build requires the new place (`requiresNew`). Reading or writing the key
  there failing is an error: the app reports it (Storage: no key) and seals nothing that run.
- Development and ad-hoc builds keep the fallback.
- A key still in the old place is moved as before; a move that fails is the same error in a release.

## Consequences

- A release on a Mac whose Secure Enclave keychain cannot be used opens no sealed state, rather than keep the key unwrapped.
- Not observed in an installed release yet: the team is read from the running code's signature (`CodeSigning`).
