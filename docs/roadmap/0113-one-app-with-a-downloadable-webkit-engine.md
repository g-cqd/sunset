---
status: in-progress
blocked-by: nothing
date: 2026-11-23
---

# 0113 — One app; Sunset's own WebKit a component to download and update, the engine chosen by the person

The owner (2026-11-22, after 0112): later, a single Sunset whose patched WebKit is a component downloaded and updated
from within the app; the person chooses between the system's WebKit and Sunset's.

The owner (2026-11-23): to be started now, not later; and with 0115 (the engine updated on a schedule), whose releases are
what this app downloads. The present way of loading the bundled engine (`DYLD_FRAMEWORK_PATH` and the
`allow-dyld-environment-variables` entitlement, the outside audit's CRIT-02) is what step A must replace: a downloaded
engine cannot be loaded that way safely.

| Step | What | Status |
|---|---|---|
| A | Research: can one process load either WebKit (system or a downloaded framework) chosen at launch; what signing, notarization, library validation and the hardened runtime allow for a downloaded framework and its XPC services | done (diaries 2026-11-23-02 and -05): loaded by path, system frameworks (AVKit among ten our WebKit loads) bring the system's WebKit in; a load command (`LC_DYLD_ENVIRONMENT`) in the executable sets the framework path with no loader exception, outside variables still ignored, a folder without WebKit falls back to the system's. Notarization of it not probed |
| B | ADR: where the component lives, how it is signed, checked and updated, how a change of engine takes effect (relaunch) | done: ADR-0124 accepted (diaries 2026-11-23-05, -08); patch 0037 |
| C | Download, check (signature, team, version) and update the engine; keep the one before until the new one opens | in progress: the native app carries the engine's services and looks for `SunsetEngine` beside it; a half-installed engine is set aside (diary 2026-11-23-10). done (`make-engine-archive.sh` notarized 75 MB zip, all 8 items verified by `SecStaticCodeCheckValidity`, `SunsetUpdate` + `AppEngine` + `EnginePlace`); end-to-end live download/switch/delete in Settings still to try |
| D | The choice in Settings, native or the component, switched back and forth; the component deleted to free its space; updated automatically or by hand (owner, 2026-11-23); the engine's age said as `AppEngineFreshness` does now | not-started |
| E | Retire the second app: Sunset WebKit's data already shared (0112) | not-started |

Not done: steps C to E; in A, notarization of the load command, and an engine never notarized. Known from 0112: the two engines compile the content blocking lists over each other's in the shared
folder; one app with one engine at a time would end that.


## Revision (2026-11-23, ADR-0125)

Replaced the external `SunsetEngine` folder with two complete notarized variants of the same `Sunset.app` (`studio.aemi.sunset`), switched via the single-archive updater (`SSDLTA2`), with per-variant `WKWebsiteDataStore` IDs.
