---
status: proposed
date: 2026-11-05
---

# 0022 — Remote control: one typed command model; socket and CLI first; MCP and XPC are adapters

## Context

Owner note n1 (2026-11-05): the terminal should be completely drivable remotely (MCP, CLI or XPC; best way to be investigated), AI agents would benefit from a stdio MCP server, not the utmost priority. Investigation: `docs/research/remote-control.md` (kitty's in-band JSON protocol with per-action authorisation, WezTerm's CLI over a mux socket, Ghostty's AppleScript and App Intents).

## Proposal

- A single typed, versioned command model (observe, act, wait; ids; bounds), implemented in the headless core (roadmap 0004's orchestration API) and encoded as protobuf and JSON.
- Transports are adapters, in this order: unix socket with the `sunsetctl` CLI; `sunsetctl mcp` (stdio MCP server translating the same commands into tools and resources); XPC on macOS; in-band control only as an opt-in, off-by-default adapter.
- Authorisation belongs to the model: capabilities of (window scope, action globs, read limits); per-window environment tokens for self-control; user grants for wider scope; defaults deny; reading and typing are separate grants; everything logged. Builds on ADR-0010.

## Open

The questions in the research note (kitty compatibility, MCP transport choice, where the MCP code lives, the agent threat model). Accept after the command model is written down as a spec and one adapter exists end to end.
