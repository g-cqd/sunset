---
status: in-progress
blocked-by: nothing
date: 2026-11-23
---

# 0122 — Sunset updates itself, and its components, from its GitHub releases

The owner (n135, 2026-11-23): an update mechanism in the app, with no third-party framework, open source, that depends only
on what Sunset already has (GitHub: releases, repository, pages); incremental updates where possible; automatic updates the
person can turn off; the update dialog shows the release notes between the two versions; an update centre shows the app's
updates and its components' (roadmap 0113: the WebKit engine).

Why it is shaped so: ADR-0122.

## Steps

| Step | What | Status |
|---|---|---|
| A | Research: what a release changes between builds; what deltas save; where the feed lives | done (diary 2026-11-23-03) |
| B | The feed and the choice: GitHub's releases read into releases (version, build, flavour's asset, notes); the newest one for this build and channel; the notes between the two | done (`ReleaseFeed`, `UpdateChoice`) |
| C | Deltas: our own binary delta (format, patch applied, a tool that makes them), per changed file; a manifest of the bundle's files and their hashes | done (`BinaryDelta`, `UpdatePackage`, `BundleManifest`, `SunsetDeltaTool`) |
| D | Install: downloaded or patched into a staging copy beside the app, every file's hash checked, the whole signature checked (our team, notarized, the same identifier, a later build), swapped in at quit, run again | written: `UpdateStaging`, `SignatureCheck`, `BundleSwap` (tested); `AppUpdates`, `UpdateTransfer`, `installAtQuit`: seen updating a test copy, at Restart to Update and at quit (diary 2026-11-23-06) |
| E | The update centre in Settings (the app and its components: version, what's new, check, update, automatic on or off) and the dialog with the notes between the two versions | written: `UpdatesCenter` (Settings › General › Updates, its row seen); `UpdateWindow` remade with the sky's band and the notes laid out (seen) |
| F | Releases make the manifest and the deltas from the last few builds, as assets beside the zip | done: `Scripts/make-update-packages.sh` (run on alpha.11), a step in the release workflow (not run) |
| G | Components (roadmap 0113): the engine published, checked and installed the same way | blocked-by: 0113 B |

Not done: G; a real release has not updated itself yet (the first that can is alpha.12, to alpha.13): seen only on two test builds through a local list. Not covered: a download's progress, a package's resume.


## Revision (2026-11-23, ADR-0125)

Upgraded to single-archive range-addressed deltas (`SSDLTA2`, capped at `K = 3` previous builds + same-build peer variant, 65% size cutoff), Ed25519 signed release index (`release-index.json` + `.sig`, main + backup keys), bounded streaming LZMA (`BoundedLZMA`), HTTPS GitHub host pinning, `If-Match` range fetches, download progress, and O(N) re-signed binary fast path.
