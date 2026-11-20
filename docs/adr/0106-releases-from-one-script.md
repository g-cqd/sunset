---
status: accepted
date: 2026-11-20
---

# 0106 — Releases come from one script, on a tag, signed with the Developer ID behind g-cqd

## Context

The owner asked for an alpha people can download, and for CI to make the later ones (2026-11-20). swift-ci packages
command-line tools, not apps (its README: an app ships through the project's own commands). Sunset already builds its app with
`Scripts/make-app.sh` and notarises it with `Scripts/notarize-app.sh` on the owner's Mac. The repository is public.

## Decision

- **One script, `Scripts/package-release.sh TAG`**, used on the owner's Mac and in CI: the release build, notarised and stapled,
  zipped with `ditto`, its SHA-256 beside it. The version people see is the tag's three numbers (`MARKETING_VERSION`); the
  build number is the count of commits (it grows, and `CFBundleVersion` takes only numbers).
- **A tag `v*` publishes** (`.github/workflows/release.yml`): the secrets go into a temporary keychain and files under the
  runner's temporary folder, removed at the end whatever happens; the built app must launch (`Scripts/smoke-launch.sh`) and pass
  Gatekeeper before `gh release create` attaches the zip and its checksum. A tag with a suffix (`-alpha.1`) is a pre-release.
  The note is `docs/releases/<tag>.md`, written before the tag; the job fails without it.
- **By hand**, the same job builds ad hoc without any secret, as a check that the app still builds on a runner.
- **The signature is the Developer ID of the team behind g-cqd** (the owner, 2026-11-20), not one of a company's teams.
- **A release built on a Mac comes from a clone in a neutral folder** (`/tmp`): a build records the absolute paths of its
  sources and intermediates (about 3,000 strings, and the Metal library's), which would otherwise publish that Mac's user name.

## Consequences

- The secrets (listed at the top of `release.yml`) are the owner's to add; until then a tag fails at the signing step and
  publishes nothing.
- Apple silicon only, as the build is today; a universal build is a change to `make-app.sh`.
