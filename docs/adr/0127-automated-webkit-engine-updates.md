---
status: accepted
date: 2026-11-25
---

# ADR-0127: Automated WebKit Engine Updates — Split CI Check and Local Mac Build/Auto-Release

## Context

Sunset's WebKit variant ships its own WebKit frameworks built from `Engine/WebKit/base` plus our patch series in
`Engine/WebKit/patches/` (ADR-0110, ADR-0125). Because macOS security updates do not reach the bundled engine, Sunset must
keep its WebKit base current on a schedule and react quickly to WebKit security advisories (roadmap 0115, threat model D10).

A Release build of WebKit (`WebKitBuild/Release`) requires ~40 GB on disk (42 GB including the sparse checkout) and ~60
minutes from scratch on Apple silicon, whereas standard GitHub-hosted `macos-26` runners provide ~14 GB free disk space.
Meanwhile, our warm WebKit tree already lives on the developer Mac, and all signing keys (GPG `9FE7C7E8522EE497`, GitHub
credentials, Ed25519 release-index key) live inside the signing VM (`gcqd-dev`).

## Decision

Split automated WebKit maintenance into two cooperative layers:

1. **Daily advisory & patch-series dry-run in GitHub Actions (`.github/workflows/webkit-check.yml`)**
   - Runs daily (`cron: "23 6 * * *"`, plus `workflow_dispatch`) on `ubuntu-latest` (< 1 minute, minimal disk).
   - Runs `Scripts/webkit.sh behind` (reading the base commit's date from GitHub's API when no local WebKit tree is present)
     to detect WebKit security advisories newer than `Engine/WebKit/base`.
   - Runs `Scripts/webkit.sh check` — a temporary minimal sparse checkout containing only the ~70 files touched by
     `Engine/WebKit/patches/*.patch` — to verify every patch still applies cleanly against WebKit `main` (and report any
     patches already upstreamed).
   - Opens or updates one tracking issue when an advisory is newer or when a patch breaks, and auto-closes it when clean.

2. **Scheduled local Mac build, test, and auto-release (`Scripts/webkit-auto-update.sh` + LaunchAgents)**
   - Installed via `Scripts/install-webkit-schedule.sh install`:
     - `studio.aemi.sunset.webkit-daily` (daily 07:15): exits immediately unless `Scripts/webkit.sh behind` reports a newer
       advisory.
     - `studio.aemi.sunset.webkit-weekly` (Sunday 04:00): runs unconditionally.
   - Refuses to run if the working tree is dirty, off `main`, or ahead of `origin/main` (never clobbers in-progress work).
   - Runs `Scripts/webkit.sh update`: fetches WebKit `main`, applies patches three-way (dropping any already upstream), builds
     Release WebKit incrementally in the warm tree, and runs `TestWebKitAPI` + layout tests against
     `Engine/WebKit/known-failures`.
   - On green: commits `Engine/WebKit/base`, re-exported patches, and release notes; pushes Gigi-authored, GPG-signed commits
     through `push-vm.sh`; creates and pushes the next GPG-signed tag (`v0.1.0-alpha.N+1`); packages and notarizes both
     variants (System WebKit + Sunset WebKit) with `SSDLTA2` deltas; signs `release-index.json` + `.sig` on `gcqd-dev`; and
     publishes the GitHub release automatically.
   - On failure at any stage: leaves `Engine/WebKit/base` and `main` untouched (before push) and files a GitHub issue with
     the diagnostic tail via `gcqd-dev`.

## Consequences

- Security advisories and patch-series drift are caught daily in CI with zero paid runner minutes and zero disk risk.
- Full WebKit compilation stays warm and incremental on the Mac, and every commit, tag, and release index stays signed by the
  existing Gigi GPG key and Ed25519 release key in `gcqd-dev` (no new signing key needed for GitHub Actions).
- Trade-off: the weekly/advisory build requires the Mac to be awake and `gcqd-dev` unlocked (`gcqd-unlock.service` keeps it
  unlocked across reboots); `launchd` runs missed `StartCalendarInterval` jobs on next wake.
- If a self-hosted macOS runner or larger hosted runner is adopted later, `Scripts/webkit-auto-update.sh` can be invoked from
  a workflow directly without changing the update or verification logic.
