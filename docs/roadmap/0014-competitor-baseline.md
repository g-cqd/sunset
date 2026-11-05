---
status: in-progress
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

**Not done:** the harness itself (vtebench workloads, idle wakeups, footprint, startup, latency proxy). Next: install or build `vtebench` (Alacritty's tool), drive each terminal as a process (TerminalKit's `Scripts/verify-reset-ladder.py` is the model), record numbers in the diary.
Caveat to keep: the terminals' own default settings differ (vsync, fonts, shaders); the harness fixes font, size, window and settings for all.
