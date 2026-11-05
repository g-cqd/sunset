---
status: proposed
date: 2026-11-05
---

# 0003 — A platform-free headless core; renderer, windowing and PTY behind seams

Layers: **core** (VT parser, screen and scrollback, modes, replies, protocols, colour pipeline; pure Swift, no Darwin-only API, no UI) → **host** (PTY and process, behind a seam with Darwin and Linux implementations) → **renderer** (CPU reference, Metal, Vulkan) → **shell** (AppKit app; Wayland/X11 app). The headless core is also a product: spawn a program, feed keys and resizes, read the screen and replies from code, which is what TerminalUI and `ask` need as an oracle (TerminalKit roadmap 0026 phase 1). Linux is possible without redesign because only seams differ.
