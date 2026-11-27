---
status: accepted
date: 2026-11-27
---

# 0131 — A release is one command, in parallel, from a commit CI passed

## Context

alpha.19 took about forty minutes of packaging (a release build from scratch in `/tmp`, two notarisations one after the
other, update packages from three older builds of each variant one after the other) and waited three times on CI runs that
a later push cancelled. The owner asked for releases that are not that slow (2026-11-27).

## Decision

- **`Scripts/release.sh TAG [COMMIT]`** does the whole release: both variants, their notarisation, the update packages, the
  SBOM, the signed index, the signed tag, the GitHub release, the install. It replaces running `package-release.sh`,
  `package-variants.sh`, the SBOM and the upload by hand (those scripts stay, and `release.sh` uses them).
- **It releases what CI passed**: without COMMIT, the newest commit of main whose CI succeeded. A release never waits on CI,
  and a push during a release cancels nothing it needs.
- **What does not depend on each other runs at once**: the SBOM and the update tool's build beside the app's build; the
  two notarisations together (the WebKit variant is wrapped from a copy while the native one is notarised); the two
  variants' update packages together.
- **The release build is incremental**: the worktree and its build folder stay between releases, in
  `sunset-release` in the Shared folder beside the users' homes. That folder names no user (as ADR-0106's `/tmp` clone did, so that no user name is published), and
  the built app is checked for the home folder's path before anything is signed.
- **An update package covers the latest release only** (and the other variant at the same build): a Sunset older than
  that downloads the zip.
- **CI**: the tests in the Release configuration run nightly, on tags and by hand, no longer on every push; a push is
  checked in Debug (about ten minutes). Making the installed Swift the one `xcodebuild` uses is swift-ci's
  (`setup-swift`, `for-xcode`), not this repository's.

## Consequences

ADR-0106's `/tmp` clone is replaced by the kept worktree. A Sunset two releases behind updates with the full zip.
