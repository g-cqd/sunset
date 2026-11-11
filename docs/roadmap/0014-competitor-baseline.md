---
status: partly-done (as of 2026-11-11: vtebench comparisons run several times; idle and footprint once; startup and latency not (task t140).)
blocked-by:
date: 2026-11-05
---

# 0014 — Competitor baseline: kitty, Ghostty, WezTerm, Alacritty on this machine

Install the three missing terminals as oracles (ADR-0004; `brew install --cask ghostty wezterm alacritty` is the likely route, unverified), check in a harness that drives all of them as processes: vtebench workloads, idle wakeups, physical footprint at launch/after N tabs/after 1 M lines, startup, a latency proxy. Output: the table in research/performance-study.md §3 filled with *our* numbers. Without this, 'better than all of them' is unmeasurable; this entry gates every performance claim.

## Installed 2026-11-05 (owner approved)

| Terminal | Version | How | Notes |
|---|---|---|---|
| kitty | 0.49.2 | already present (`/Applications/kitty.app`) | |
| Ghostty | 1.4.0 | `brew install --cask ghostty` | `/Applications/Ghostty.app`; CLI `+version` works |
| WezTerm | 20240203-110809-5046fc22 | `brew install --cask wezterm` | **the last tagged release is from Feb 2024**: a stale oracle; its source `main` (read for the performance study) is newer than this binary |
| Alacritty | 0.18.0-dev (`aecf0f6`) | **built from source** (`cargo build --release --locked`, 1 m 30 s, in `/tmp/ref/alacritty/target/release/alacritty`, 7 MB, unsigned) | the Homebrew cask was **disabled on 2026-09-01 for failing the Gatekeeper check**; a source build is a CLI binary, not an app bundle, and differs from the project's releases |

**Done (first pass):** `bench/compete.sh` + `bench/summarize.py` run vtebench in each terminal with the same grid, font and no config; results in `bench/results/2026-11-05/` (see its caveats: load average 7–17, 10 samples, one pass). **Not done:** idle wakeups, physical footprint, startup, latency proxy, a quiet-machine repeat. Next: install or build `vtebench` (Alacritty's tool), drive each terminal as a process (TerminalKit's `Scripts/verify-reset-ladder.py` is the model), record numbers in the diary.
Caveat to keep: the terminals' own default settings differ (vsync, fonts, shaders); the harness fixes font, size, window and settings for all.

## Idle and footprint (2026-11-05, one sample each, scrollback 100,000 lines / Ghostty 100 MB, 120x40, JetBrains Mono 14, no config)

| Terminal | footprint at launch | footprint after 1 M lines (peak) | idle wakeups/s | idle Minstr/s |
|---|---|---|---|---|
| kitty 0.49.2 | 101.6 MB | 469.8 MB (534.4) | 4.4 (0.5 later) | 2.4 (0.9 later) |
| Ghostty 1.4.0 | 133.6 MB | **136.0 MB** (237.8) | **15.2–16.4** | 5.3–6.9 |
| WezTerm 20240203 | **63.0 MB** | **81.1 MB** (136.9) | 5.7–5.8 | 3.7 (0.7 later) |
| Alacritty 0.18.0-dev | 78.4 MB | 411.6 MB (521.0) | **0.3** | **0.04–0.13** |

Bar for Sunset (to beat the best of each column): launch < 63 MB; after 1 M lines < 81 MB; idle wakeups <= 0.3/s; idle instructions < 0.04 M/s. A first sample of the first run of the 1 M-line case was taken while the terminals were still rendering (kitty 494 Minstr/s, WezTerm 2,480 Minstr/s); the script now waits for the output to finish.
Reading, not a result: WezTerm's and Ghostty's compact scrollback shows (both under 140 MB after 1 M lines); kitty's and Alacritty's cell-per-column storage costs 330–390 MB more. Ghostty's idle wakeups (15/s) are the highest here, Alacritty's the lowest. GPU memory accounting in `phys_footprint` is not verified.
