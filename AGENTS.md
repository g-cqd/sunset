# Working in Sunset

Read [docs/WHITE-PAPER.md](docs/WHITE-PAPER.md) first; it binds everything below.

| Thing | Where | Rule |
|---|---|---|
| Decision | `docs/adr/NNNN-title.md` | One per file, `status:` and `date:` front matter; a decision changed by evidence is a new ADR that supersedes the old one. |
| Unit of work | `docs/roadmap/NNNN-title.md` | One per file; `status:` (`not-started`, `in-progress`, `done`, `blocked`), `blocked-by:`, `date:`, one top-level title; say what is *not* done. |
| Probe history | `docs/diary/YYYY-MM-DD-NN.md` | Claim → probe → verdict tables; no file over 256 lines. |
| Research | `docs/research/` | Claims until probed. Include vendor numbers as the vendor's, never as ours. |
| Architecture | `docs/design/` | What is intended; ADRs say why; neither is a log. |
| Tasks and notes | the agent `tasks` and `notes` tools | One task per roadmap entry; notes from the owner are acknowledged, then fulfilled or dismissed. |

## Loop

1. Read open tasks and new notes; pick the next unblocked roadmap entry.
2. Name the claim, probe it, record it in the diary. **Red first**, observed and recorded; commits need not build, the tip you hand back must (ADR-0007).
3. Measure hot paths before and after (release only, percentiles, same harness), against the oracles where a comparison exists.
4. **Never wait on CI**; mutation testing runs in CI only.
5. Update the roadmap entry, write or supersede ADRs, update the task.

## Rules specific to this repository

- The core (parser, screen, modes, replies, PTY host) imports no Darwin-only API outside a seam, and no UI.
- Oracles (kitty, ghostty, wezterm, Terminal.app, SwiftTerm, libghostty) run as processes in tests and benchmarks; they are never linked or vendored. Their numbers are quoted as theirs.
- Anything an untrusted program can ask the terminal to do has a policy and a test for it (white paper §9).
- Style and gates: adopt TerminalKit's (aemi's synced `.swift-format`/`.swiftlint.yml`, `Scripts/quality.sh --check`) when the first target lands.
