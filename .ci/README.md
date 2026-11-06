# CI

Written 2026-11-05 from TerminalKit's and ask's setups; **not yet run on GitHub** (nothing has been pushed), so the configuration is unverified.

- `.github/workflows/ci.yml` calls the family's pinned swift-ci workflow, configured by `action.json`: quality (swift-format, SwiftLint metrics, the shipped-library discipline) and the macOS release tests on every push, pull request and nightly. macOS only for now (the core is platform-free, a Linux leg comes with roadmap 0013).
- `.github/workflows/mutation.yml` runs mutation testing once a day on the Sources files changed in the last day, and on Mondays and by hand on every file, uploading a fresh baseline (`.ci/baselines/mutation.json`, commit it by hand). A surviving mutant that is not in the baseline fails the run and becomes a red test. `Scripts/mutate-changed.sh` is the same script ask uses, with the baseline path changed.
- Benchmarks are not compared in CI yet (`Benchmarks/` has no thresholds for the parser and screen); TerminalKit's `benchmarks` job is the model when they do.
- Never waited on (white paper section 1): push, carry on, read the result when it arrives.
