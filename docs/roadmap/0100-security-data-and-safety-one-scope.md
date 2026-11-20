---
status: not-started
blocked-by: the owner's word on docs/design/0006, 0007 and ADR-0100 (proposed)
date: 2026-11-19
---

# 0100 — Security, data handling and safety: one scope

The owner, 2026-11-19: "restudy the realisticness of the already open points and then resynthesize the whole set of
features, so that we can work to make a whole cohesive scope for security, data handling, safety, maybe even draft a threat
model". Realism: docs/research/security-realism-2026-11-19.md (diary 2026-11-19-07). Threat model: docs/design/0006. The scope
and its stages: docs/design/0007.

| Step | What | Status |
|---|---|---|
| A | The open points studied again, probed where it was cheap (FileVault, the image's cost, WebKit's store paths and protections) | done |
| B | Threat model and scope drafted; staging S1–S6 proposed | done |
| C | The owner decides: the drafts, the staging, what is dropped (t48 D, t51's image, t59's further runs), the four open questions in 0007 | in-progress: decided 2026-11-20, the drops (all three); OSC 52 write allowed with a setting (ADR-0010); macOS does not ask for the Keychain after an install (the owner's experience); the data sets bundled and refreshed (ADR-0108); A4 covered for WebKit's data beyond the cookie jar (task t137). Not decided: the threat model itself: the owner wants it hardened and refined with the state of the art in each field involved first (task t136) |
| D | Once decided: roadmap 0051, 0058 and 0090 brought in line with 0007's stages | not-started |

Not done: the threat model refined (t136), then its acceptance; D; nothing is built.
