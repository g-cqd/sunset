---
status: accepted
date: 2026-11-24
supersedes: the mutation bullet of white paper section 1 ("belongs to CI, scheduled and on pull requests, never to the local loop")
---

# Mutation testing runs on pull requests and locally in the background, never on a schedule, never in the loop

## Context

Sunset's mutation testing used a third-party tool in a daily workflow. It moved to litmus, through swift-ci's `mutation` command
(2026-11-24). The owner's decision on where it runs: **only asynchronously on the owner's machine, or on pull requests**. A schedule
without a baseline is a red run every night; a run of up to two hours is not something the inner loop or a gate can wait for.

## Decision

- CI runs the `mutation` command on **pull requests** only (`"cadence": ["pull-request"]` in `.ci/action.json`), on macOS, for up to an hour,
  in a copy of the project (never `in-place`: the same command runs on the owner's machine, where it must not touch a tree being edited). No schedule, no manual dispatch.
- Locally, `Scripts/mutate-async.sh` starts the same command (`.ci/swift-ci run mutation`) **in the background**: it returns at once, writes
  `.build/mutation/<time>.log`, and refuses to start a second run while one is going. Nothing waits on it: the gate, the tests and the
  loop never run it, and `swift-ci local quality` does not (`quality.local` stays empty).
- A surviving mutant that `.ci/baselines/litmus.json` does not accept is a red test like any other: recorded as a roadmap entry or a diary line,
  then fixed. The baseline does not exist yet; the first run's result is the one to commit by hand.

## Consequences

- The white paper's bullet in section 1 changes to say so; AGENTS.md and `docs/quality.md` follow.
- The repository holds no other mutation tool.
- Not decided here: which sources are mutated (the pure models, `Sources/SunsetCore`, `SunsetPane`, `SunsetConfig`, `SunsetDocuments`).
