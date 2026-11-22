---
status: not-started
blocked-by: nothing
date: 2026-11-22
---

# 0113 — One app; Sunset's own WebKit a component to download and update, the engine chosen by the person

The owner (2026-11-22, after 0112): later, a single Sunset whose patched WebKit is a component downloaded and updated
from within the app; the person chooses between the system's WebKit and Sunset's.

| Step | What | Status |
|---|---|---|
| A | Research: can one process load either WebKit (system or a downloaded framework) chosen at launch; what signing, notarization, library validation and the hardened runtime allow for a downloaded framework and its XPC services | not-started |
| B | ADR: where the component lives, how it is signed, checked and updated, how a change of engine takes effect (relaunch) | not-started |
| C | Download, check (signature, team, version) and update the engine; keep the one before until the new one opens | not-started |
| D | The choice in Settings; the engine's age said as `AppEngineFreshness` does now | not-started |
| E | Retire the second app: Sunset WebKit's data already shared (0112) | not-started |

Not done: everything. Known from 0112: the two engines compile the content blocking lists over each other's in the shared
folder; one app with one engine at a time would end that.
