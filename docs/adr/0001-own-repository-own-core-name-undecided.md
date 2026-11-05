---
status: accepted
date: 2026-11-05
---

# 0001 — A repository of its own, our own emulator core, name undecided

## Context

TerminalKit is the client side of a terminal (it writes sequences and decodes input). TerminalKit roadmap 0026 ('AemiTerminal') already planned an emulator: headless first, then macOS, then iOS. The owner (2026-11-05) asked for a Swift terminal based on our tooling, kitty-graphics compatible with every modern feature, macOS first and Linux a target, and said `Aemi*` names are for dependencies only, never end products; the name is to be decided.

## Decision

- The terminal is its own repository (placeholder directory `terminal-tbd`), consuming TerminalKit and Aemi.
- We write our own emulator core; other emulators are oracles (ADR-0004).
- Roadmap 0026 in TerminalKit is superseded by this repository's roadmap; TerminalKit keeps the client-side half.
- The name is open; no source, product or document bakes in `terminal-tbd`.

## Evidence

Read: TerminalKit roadmap 0026, ask ADR-0001 (the name AemiTerminal was once planned for the stack), investigation snapshot (docs/research). SwiftTerm (75k lines Swift) and libghostty-vt exist; adopting either was rejected by the 'only our own tooling' constraint (ADR-0002).
