---
status: proposed
date: 2026-11-20
---

# ADR-0111: Two releasable builds: Sunset on macOS's WebKit, and Sunset WebKit bundling ours

## Context

The owner, 2026-11-20: "we need to be able to have both builds possible and releasable, one with macos native one with
bundling our patched webkit". ADR-0110 keeps our patches as a series on a WebKit base; roadmap 0048 C asks for an app on it.
Probed (diary 2026-11-20-23):

- Rewriting WebKit's install names to `@rpath` loads ours, but system frameworks AppKit loads (SafariServices,
  LinkPresentation, DataDetectors, AuthKitUI…) link the system's WebKit: both were in the process, and no page loaded.
- The loader's variables (`DYLD_FRAMEWORK_PATH`, and `__XPC_` ones for WebKit's processes) replace the system's WebKit for
  every framework at once, as WebKit's own tools do. A hardened binary reads them only with
  `com.apple.security.cs.allow-dyld-environment-variables`, a hardened runtime exception notarization accepts.
- WebKit's processes must be the app's own XPC services (`Contents/XPCServices`); otherwise WebKit falls back to the
  system's, which run the system's WebKit, and every page stops.

## Decision

1. **Sunset** (`Scripts/make-app.sh release`): unchanged, on macOS's WebKit; signed, hardened, notarized as before.
2. **Sunset WebKit** (`Scripts/make-webkit-app.sh` on that build and a WebKit build of `Engine/WebKit`): its own
   identifier (`studio.aemi.sunset.webkit`), so its settings, profiles and website data are its own (a newer WebKit may
   change stores so the system's cannot read them). WebKit's frameworks in `Contents/Frameworks`, its processes in
   `Contents/XPCServices`; a launcher (`Engine/WebKit/launcher.c`) as the executable sets the loader's variables to the
   app's frameworks only (it removes any library insertion) and runs Sunset.
3. Both signed with the team's Developer ID, hardened, timestamped, notarized and stapled by the same script. Sunset WebKit's
   binaries carry one more exception than Sunset's: reading the loader's variables; the web content process also JIT
   (as WebKit's own build). Library validation stays on: every framework carries the team's signature.
4. Sunset WebKit has its own App ID and Developer ID provisioning profile (the owner, 2026-11-20), kept beside the
   notary's credentials (`~/.config/sunset-signing/webkit.provisionprofile`), never in the repository; the script embeds
   it and signs with the native build's team entitlements for this identifier (its keychain group), the team read from
   the profile. Without one it falls back to an ad hoc build's entitlements (Sunset keeps its keys in its vault).
5. `Scripts/install-app.sh` installs either build in `~/Applications` under its own name.

## Consequences

- The exception widens what a local attacker who can already start Sunset WebKit's binary with their own variables could
  load into it; library validation still refuses libraries not signed by the team. To weigh in the threat model (t136).
- WebKit's processes are sandboxed by WebKit's own profiles (checked: reads of `/Users` denied, as the system's), without
  the system's private entitlements; what those add is not known here (t136).
- Its size: 331 MB (Sunset alone is far smaller). Each WebKit move (ADR-0110) is followed by a build and a notarization
  of Sunset WebKit.
