---
status: proposed
date: 2026-11-19
---

# A threat model governs security decisions

## Context

Security work so far came from audits and requests one at a time (0051, 0012, ADR-0010, ADR-0089, the credentials staging).
Re-studied (docs/research/security-realism-2026-11-19.md): two points cost more than they protect once measured against
who attacks. t48 D's KDF guards a code nobody types. t51's encrypted image is open to every process of the same user
while Sunset runs, and FileVault is on.

## Decision (proposed)

- docs/design/0006-threat-model.md (assets D1–D9, adversaries A1–A10, boundaries, threats, gaps) is the reference. An ADR
  that touches data or untrusted input names the adversaries it answers and the rows it closes or adds.
- docs/design/0007-security-and-data.md holds:
  - the principles: one record format, one sealing, one backup; keys by role; the person's act before anything leaves or
    fills;
  - the data map: each class's place, protection, retention, ways out, deletion, each with a test;
  - the stages.
- Dropped, unless the owner keeps them:
  - t48 D (the recovery code is a random 256-bit key);
  - t51's encrypted image (low worth; the cookie jar sealed at quit and caches out of backups instead);
  - t59's further runs (measured once: attach 0.36 s, commits 1.8×).

## Consequences

The threat model is a living file. When a stage of 0007 ends, it is read again, and a gap closes only with a red test.
