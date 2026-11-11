---
status: not-started (as of 2026-11-11: ADR-0022 proposed; nothing built. After the web milestone for pages (task t136).)
blocked-by: 0004
date: 2026-11-05
---

# 0016 — Remote control (owner note n1; not the utmost priority)

Steps: write the command model as a spec (observe / act / wait, ids, bounds, capabilities) on top of roadmap 0004's headless API; the socket server and `sunsetctl`; the MCP stdio adapter (decide whether the MCP wire types are promoted from `AskMCP` into an Aemi package shared with ask); XPC on macOS; the authorisation UI (grants list, revoke, log); differential tests against kitty `@` and `wezterm cli` on the commands they share. Research and ADR-0022 (proposed) exist; nothing is built.
