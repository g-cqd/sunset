---
status: not-started
blocked-by: owner approval to install oracle terminals
date: 2026-11-05
---

# 0014 — Competitor baseline: kitty, Ghostty, WezTerm, Alacritty on this machine

Install the three missing terminals as oracles (ADR-0004; `brew install --cask ghostty wezterm alacritty` is the likely route, unverified), check in a harness that drives all of them as processes: vtebench workloads, idle wakeups, physical footprint at launch/after N tabs/after 1 M lines, startup, a latency proxy. Output: the table in research/performance-study.md §3 filled with *our* numbers. Without this, 'better than all of them' is unmeasurable; this entry gates every performance claim.
