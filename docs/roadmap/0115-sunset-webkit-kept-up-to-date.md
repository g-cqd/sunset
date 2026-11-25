---
status: in-progress
blocked-by: nothing
date: 2026-11-25
---

# 0115 — Sunset WebKit kept up to date, on a schedule

Sunset WebKit carries its own WebKit (main at `Engine/WebKit/base`, 37 patches of ours) and gets no WebKit security fixes
from macOS. Implemented in the split model of ADR-0127: daily advisory and patch dry-run in GitHub Actions, full incremental
build + test + auto-release on the Mac via LaunchAgents.

## What exists

- `Scripts/webkit.sh`:
  - `behind`: whether WebKit published a security advisory after the base's date (exit 1: an update is due); falls back to
    GitHub's API when no local WebKit tree exists, so it works on Linux CI runners.
  - `check [COMMIT]`: dry-runs the patch series against WebKit `main` (or `COMMIT`) in a temporary minimal sparse checkout
    of only the files touched by `Engine/WebKit/patches/*.patch` (~30 s).
  - `update [COMMIT]`: fetches WebKit's main, applies the series (three-way, rerere; patches WebKit took upstream dropped),
    builds Release, tests against `Engine/WebKit/known-failures`; only when all of that passes moves `base` and re-exports.
- `.github/workflows/webkit-check.yml`: daily scheduled check (`23 6 * * *` + `workflow_dispatch`) running `behind` and
  `check`, opening/updating/closing tracking GitHub issues.
- `Scripts/webkit-auto-update.sh` + `Scripts/install-webkit-schedule.sh`: daily (advisory-gated, 07:15) and weekly (Sunday
  04:00) Mac LaunchAgents that run `webkit.sh update` on the warm tree, commit + GPG-sign + push + tag via the signing VM,
  notarize both variants, build `SSDLTA2` deltas, sign `release-index.json`, and publish the GitHub release on green.

## Steps

| Step | What | Status |
|---|---|---|
| A | Scheduled check: daily `webkit.sh behind` + `webkit.sh check` in GitHub Actions (`.github/workflows/webkit-check.yml`), plus daily/weekly Mac LaunchAgents (`Scripts/install-webkit-schedule.sh`) | done (2026-11-25) |
| B | On success: commit moved `base` + re-exported series + release notes, push signed via VM, tag, package both variants + signed index, publish GitHub release (`Scripts/webkit-auto-update.sh`) | done (2026-11-25; dry-run verified, first live green update not yet observed) |
| C | On failure: report what broke (patch conflict, build error, or test failure) in a GitHub issue, leave `base` untouched | done (2026-11-25) |
| D | Auto-release on green (both variants, notarised, signed release index, GPG-signed tag via signing VM; ADR-0127) | done (2026-11-25; not yet observed end-to-end on a live WebKit advance) |
| E | The app says when its engine is old (exists: eight weeks) and fetches the new engine itself via Sunset's updater (ADR-0125) | done (ADR-0125 replaced standalone engine downloads with two-variant byte-range `.deltas`) |

Not done: observing the first live unattended run of `Scripts/webkit-auto-update.sh` advance `Engine/WebKit/base` and publish a release end-to-end.
