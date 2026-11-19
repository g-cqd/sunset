---
status: proposed
date: 2026-11-19
---

# Credentials are a feature scope of their own, off until turned on

## Context

The owner, 2026-11-19, asked for Sunset's own password management "toggleable as a feature scope", beside Apple
Passwords. Research: docs/research/credentials/.

## Decision (proposed)

- `credentials.enabled`, off by default. While it is off:
  - no vault file;
  - no fill or save script in any page (`SignInWatch` keeps its one job, ADR-0081);
  - no menu, no settings beyond the switch.
- Vaults are files of their own (one SQLite per vault, SunsetStorage's rules of 0051 A–C from the start). They are not
  the app's state database: they open and close on their own.
- A profile names the vault it fills from, or none. A private window fills, but never offers to save.
- Turned off again, a vault stays on disk, closed; removing it is a separate act that offers a backup first.

## Consequences

- The scope has its own module (`SunsetCredentials`, no UI; `SunsetCredentialsUI` for the app). It holds the model, the
  crypto, the store and the merge rules, all testable without AppKit.
- Everything Apple holds (passkeys, the credential provider, iCloud) is a later stage behind t49 (ADR-0098).
