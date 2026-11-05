---
status: accepted
date: 2026-11-05
---

# 0007 — Red TDD stays; iteration is fast, CI is not waited on, mutation testing is CI's, commits need not build

Same decision as TerminalUI ADR-0007 (owner, 2026-11-05): red observed for the right reason before the implementation; local loop filtered; CI pushed to and read later; mutation testing only in CI; intermediate commits may be red or not build, the tip handed back or merged builds and passes the gate; a pushed commit that breaks `main` is repaired before new work lands. Diverges from TerminalKit's white paper §1 and §6 for this repository only. "Tip builds" is my reading of "not necessarily every commit"; supersede if looser was meant.
