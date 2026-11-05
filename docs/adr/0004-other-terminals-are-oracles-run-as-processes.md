---
status: accepted
date: 2026-11-05
---

# 0004 — kitty, ghostty, wezterm, Terminal.app, SwiftTerm and libghostty are oracles, never dependencies

They run as separate processes in conformance, differential-fuzz and benchmark harnesses (TerminalKit already drives kitty, ghostty, wezterm and Terminal.app this way: roadmap 0002 and `Scripts/verify-reset-ladder.py` there). Their output is a comparison input. Their throughput numbers are quoted as theirs and re-measured on our harness before being used. Consequence of the owner's 'only our own tooling' constraint (2026-11-05).
