---
status: proposed
date: 2026-11-23
---

# The WebKit engine as a component: a folder beside the app, services of its own names, chosen at launch

## Context

Roadmap 0113: one Sunset, its own WebKit a component the person downloads, switches on and off, deletes, and updates
automatically or by hand (owner, 2026-11-23). ADR-0123: the executables set the loader's framework path themselves;
a folder without WebKit falls back to the system's. Roadmap 0122 (ADR-0122): updates from GitHub releases, checked by
signature, as deltas.

## Decision (proposed)

1. **Where**: the engine's frameworks in a folder beside the app, named in Sunset's executable relative to it
   (`DYLD_FRAMEWORK_PATH=@executable_path/../../../Sunset Engine/Frameworks`, one folder per app copy; the folder of
   ADR-0123 stays first for a bundled build). Off: the folder renamed aside (`Sunset Engine (off)`); deleted: removed.
   Every change takes effect when Sunset opens again, which it offers to do.
2. **Services**: WebKit finds its processes by name (`com.apple.WebKit.WebContent`…, `ProcessLauncherCocoa.mm`), and an
   app's own services of those names would serve the system's WebKit too, without Apple's entitlements (DRM, the GPU
   process). A patch of ours makes our WebKit ask for `studio.aemi.sunset.engine.*` when the app's Info.plist says so; the
   app ships those services (our executables, ADR-0123, their path toward the engine's folder) and none of Apple's names.
   With the engine off, the system's WebKit uses the system's services, as today.
3. **Trust**: library validation (our team only), and the engine's base checked against what the app asked for
   (`refuseOtherWebKit`, a version file written by the installer): an older engine of ours swapped in is refused, Sunset
   then runs on the system's after saying so.
4. **Updates**: the engine is a release asset of its own (zip and deltas, roadmap 0122), offered in the update centre beside
   the app, with its own automatic switch.

## To probe before accepting

- The relative folder in a translocated or read-only copy (then the component cannot be installed: said so).
- ~~The patch's service names against the sandbox profiles WebKit selects by service name.~~ Done (diary
  2026-11-23-08): patch 0037; the profile follows `WebKitServiceName`; sandboxed; the system's WebKit ignores them.
- What the WebKit process launcher does when the named services are missing (the engine half-installed).
