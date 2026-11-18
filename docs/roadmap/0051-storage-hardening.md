---
status: not-started
blocked-by: nothing
date: 2026-11-18
---

# 0051 — Storage hardening, from the owner's audit

The owner, note n22 (2026-11-18): "the following informations need to be persisted to the repo and staged and scheduled in the
roadmap with priority to be addressed as soon as possible". The audit: docs/research/storage-audit-2026-11-18.md. First, before
0050.

| Step | What | Task | Status |
|---|---|---|---|
| A | The folder 0700, the databases and their WAL and SHM 0600, set on every open and on files made | t47 | not-started (0755/0644 probed) |
| B | No residue: `secure_delete` on, the WAL checkpointed and truncated on close and after deletes (history cleared) | t47 | not-started (2.7 MB WAL probed) |
| C | Less in clear: times and counts inside the sealed payload, or coarse; opaque ids for kinds; row keys by HMAC with a key of their own; a migration that reseals | t48 | not-started |
| D | The recovery code: what it is (random, or typed); a memory-hard KDF (Argon2id, our own, in an Aemi package) if it can be typed | t48 | not-started |
| E | Exports: sealed by default, or opt-in with a warning | t48 | not-started |
| F | Signing: Developer ID, hardened runtime, library validation; a Secure Enclave key wrapping the storage key | t49 | not-started (needs the owner's certificate) |

Each step: red first (a test reading the modes, the WAL, the clear columns), the cost measured where it touches the hot path
(history writes, launch).
