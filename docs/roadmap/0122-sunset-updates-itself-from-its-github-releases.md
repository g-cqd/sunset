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
| D | Install: downloaded or patched into a staging copy beside the app, every file's hash checked, the whole signature checked (our team, notarized, the same identifier, a later build), swapped in at quit, run again | in part: `UpdateStaging`, `SignatureCheck`, `BundleSwap`; not the app's side (download, when to swap, running again) |
| E | The update centre in Settings (the app and its components: version, what's new, check, update, automatic on or off) and the dialog with the notes between the two versions | not-started |
| F | Releases make the manifest and the deltas from the last few builds, as assets beside the zip | not-started |
| G | Components (roadmap 0113): the engine published, checked and installed the same way | blocked-by: 0113 B |

Not done: D's app side, E, F, G. No update has been installed by Sunset yet.
