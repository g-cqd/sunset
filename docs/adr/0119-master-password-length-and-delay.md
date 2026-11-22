---
status: accepted
date: 2026-11-22
---

# The master password: at least 12 characters; wrong ones slow the next try

## Context

The vault took any non-empty master password, and wrong ones were slowed only by Argon2 (about 0.65 s a try). The outside
audit of 2026-11-22 (HIGH-02) asked for a minimum length and throttling. The owner chose (2026-11-22): 12 characters and a
growing delay.

## Decision

- A vault is made only with 12 characters or more (`PasswordsModel.minimumLength`); the sheet says so.
- Three wrong passwords are free; after the third, the next try waits 1 s, then 2, 4, 8, 16, and 30 s from then on. While it
  waits, nothing is tried, not even the right password. A right password clears it (`UnlockThrottle`).
- The delay is kept in memory: it is against guesses through the app's window. A copy of the vault file is guessed at
  offline, where only Argon2's cost (1 GiB, 3 passes) stands, and the cost a file names is bounded (`MasterPassword.Cost`).

## Consequences

- Quitting Sunset clears the count. No change-password flow exists yet; when it comes, the same length applies.
