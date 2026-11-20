---
status: in-progress
blocked-by: the owner's repository secrets (for releases after the first)
date: 2026-11-20
---

# 0102 — Releases people can download, and the family's analyzers in CI (task t127)

The owner asked (2026-11-20) for CI/CD on the model of ask, arcleak, dolly and deadwood, and an alpha release on GitHub.
ADR-0106 says why it is shaped this way.

## Done

- **Analyzers in the quality step**: deadwood, dolly and arcleak on `Sources`, as the family's other repositories run them
  (`.ci/action.json`). The baselines were stale (dolly: 645 fingerprints, of a tree long gone); rewritten from today's tree.
  - dolly: 163 clones, the number `CloneRatchetTests` holds; t92 removes them.
  - deadwood: 17 findings. 4 really dead and removed: `previewFlags` (left by ec65f7a, which moved reading to a
    `SettingCodec`), `helpListWidth`, `WebContent.stopShare()`, `TabSidebar.Part`. 13 are reached only from tests (API kept
    for them) and are baselined.
  - arcleak: nothing.
  - `.ci/swift-ci run quality` passes on this Mac.
- **`Scripts/package-release.sh TAG`**: release build with the tag's version, notarised, zipped with `ditto`, SHA-256 beside
  it. `make-app.sh`'s build number is now the count of commits (it was `git describe`, not a number).
- **`.github/workflows/release.yml`**: a tag `v*` signs (temporary keychain), notarises, launches the app, and publishes the
  zip with `docs/releases/<tag>.md` as the note; by hand it builds ad hoc as a check. actionlint and zizmor are clean.

- **v0.1.0-alpha.1 published** (2026-11-20), a pre-release at 3543ae6 (signed tag): built on the owner's Mac from a clone
  under `/tmp` (no user name in the app), signed with the Developer ID the owner confirmed as his,
  notarised and stapled; downloaded back, unzipped, quarantined: Gatekeeper accepts it ("Notarized Developer
  ID"). The tag's Release run was cancelled by hand (no secrets yet).

## Not done

- The workflow has **not run on GitHub**: it needs the seven secrets at its top, which the owner adds.
- Sunset's CI pins swift-ci by revision; the analyzers' versions are swift-ci's.
- The app is arm64 only; no universal build.
- swift-ci's `family repin` wrote `"kind" : "localSourceControl"` beside remote URLs into Sunset's three `Package.resolved`,
  which SwiftPM then refuses ("invalid absolute path"); fixed by hand here, not in swift-ci.
