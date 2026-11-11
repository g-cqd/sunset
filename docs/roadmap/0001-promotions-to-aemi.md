---
status: not-started (as of 2026-11-11: Nothing promoted. Aemi kernels and AemiJSON are used as dependencies.)
blocked-by:
date: 2026-11-05
---

# 0001 — Promote generic pieces into Aemi (and fix TerminalKit's Linux seams)

Candidates (ADR-0002): grapheme segmentation, East-Asian width, emoji presentation and bidi into AemiUnicode (TerminalKit has its own width tables, ADR-0024 there); `AemiColor` (sRGB/P3/linear, OKLab, gamut mapping, contrast); `AemiCompression` (inflate/deflate) and `AemiImage` (PNG first); PTY/spawn; later `AemiFont`, `AemiGPU`. First: inventory what Aemi already contains by reading sources (only target names and READMEs have been read). Each promotion is a measured, pinned change (white paper: generic tools belong in Aemi). TerminalKit roadmap 0024 lists the Darwin-only parts to fix for Linux.
