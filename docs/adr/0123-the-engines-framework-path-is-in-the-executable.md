---
status: accepted
date: 2026-11-23
supersedes: ADR-0111 (point 2, how Sunset WebKit finds its WebKit)
---

# The engine's framework path is set in the executables, not in the environment

## Context

ADR-0111 had Sunset WebKit run itself again with `DYLD_FRAMEWORK_PATH` set, which a hardened process reads only with
`com.apple.security.cs.allow-dyld-environment-variables`, for Sunset and for WebKit's processes. The outside audit
(CRIT-02, 2026-11-22) named that exception: any program of the same user could start Sunset WebKit with its own loader
variables. Roadmap 0113 (the engine as a download) needed another way anyway.

Probed (diary 2026-11-23-05): frameworks loaded by path still let the system's WebKit in (ten frameworks our own WebKit
loads link it from the shared cache: AVKit, AuthenticationServices, LinkPresentation…); a load command in the executable
(`LC_DYLD_ENVIRONMENT`, linked with `-Wl,-dyld_env,DYLD_FRAMEWORK_PATH=…`) is read by a hardened, Developer ID executable
without the exception, binds those frameworks to ours, ignores the environment's variables, takes `@executable_path`, and
falls back to the system's WebKit when the folder has none. It costs nothing measurable at launch; it notarizes; it holds
when Launch Services starts the app quarantined and translocated.

## Decision

- Sunset's executable, both builds, sets `DYLD_FRAMEWORK_PATH=@executable_path/../Frameworks` (project.yml;
  `make-app.sh` refuses a build without it). The native build has no WebKit there.
- Sunset WebKit's services get executables of ours (`Engine/WebKit/service-main.c`: `WKXPCServiceMain`) with the path
  toward the app's `Frameworks`.
- No part of either app has `allow-dyld-environment-variables` (`make-webkit-app.sh` refuses one that does); Sunset no
  longer runs itself again. `BundledWebKit.refuseOtherWebKit` stays (library validation lets our team's older builds load).

## Consequences

CRIT-02 is closed for the next release. For roadmap 0113, the path can name a folder outside the bundle (relative to the
executable) where a downloaded engine is put, moved aside or deleted; the services' names are still to settle there.
