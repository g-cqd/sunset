---
status: not-started
blocked-by: the owner's choices below
date: 2026-11-23
---

# 0115 — Sunset WebKit kept up to date, on a schedule

Sunset WebKit carries its own WebKit (main at `Engine/WebKit/base`, 36 patches of ours) and gets no WebKit security fixes
from macOS. Today it is updated by hand. The owner asked (2026-11-23) for a daily or weekly workflow that updates and
patches it on its own.

## What exists

`Scripts/webkit.sh` already does the hard part:

- `behind`: whether WebKit published a security advisory after the base's date (exit 1: an update is due).
- `update [COMMIT]`: WebKit's main fetched, the series applied (three-way, rerere; patches WebKit took upstream dropped),
  built, tested against `Engine/WebKit/known-failures`; only when all of that passes is the base moved and the series
  exported again.
- `make-webkit-app.sh`, `notarize-app.sh`, the release routine (`docs/releases/`).

## Steps

| Step | What | Status |
|---|---|---|
| A | A scheduled run: daily `webkit.sh behind`; weekly (or at once when `behind` says so) `webkit.sh update` | not-started |
| B | On success: a branch with the moved base and the re-exported series, the build's numbers (patches dropped, tests, time), opened as a pull request (or a note) for the owner | not-started |
| C | On failure: what broke (the patch that no longer applies, the build error, the new test failures) reported, nothing moved | not-started |
| D | After the owner merges: Sunset WebKit built, notarised, released (or a security release at once when `behind` fired) | not-started |
| E | The app says when its engine is old (exists: eight weeks) and, later, fetches the new engine itself (roadmap 0113) | not-started |

## For the owner to choose

- **Where it runs.** A WebKit build takes hours and tens of GB: GitHub's hosted runners are too small and too short.
  A Mac of the owner's (launchd), or a self-hosted runner on one, is the likely place. Which Mac, and is it awake?
- **How much is automatic.** Update and test only, a person merging (recommended: a WebKit main build can break the series
  in ways only a person can judge); or also build, notarise and publish a release when the tests pass.
- **Signing.** A release needs the Developer ID and notary keys on that Mac, and the release tag the GPG key on mbp23.
- **How often.** Daily advisory check and weekly update, or daily update.

Not done: all of it.
