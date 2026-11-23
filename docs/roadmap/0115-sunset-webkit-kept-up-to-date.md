---
status: not-started
blocked-by: nothing (where the build fits: step A)
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

## The owner's choices (2026-11-23)

- **Where**: GitHub Actions workflows. A hosted macOS runner allows a job 6 hours and about 14 GB free; a WebKit release
  build is near both limits. To find out in step A: whether an incremental build from a cached tree fits (the cache is
  limited too), or a larger runner (paid) or a self-hosted runner registered to the workflows is needed.
- **How automatic**: released when every test passes: built, notarised and published without the owner. The signing
  material (Developer ID, the notary key) then lives in the repository's secrets, and the tag is signed in the workflow
  (not with mbp23's key): to settle in an ADR before step D.
- **How often**: a daily check for WebKit security advisories newer than the base; a full update weekly, or at once when
  an advisory is.

Not done: all of it.
