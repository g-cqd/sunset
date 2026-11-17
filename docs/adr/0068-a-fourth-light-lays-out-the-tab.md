---
status: superseded by 0069
date: 2026-11-17
---

# 0068 — A fourth light lays out the selected tab

## Context

The owner (n78): "a fourth traffic light [that] would mimic the green light's panel for the layout but for split tabs";
asked (t287), he chose five presets, a click to open the panel, and the system's accent as its colour.

## Decision

- After the zoom button, at the lights' pitch, in the sidebar's header (mirrored on a right sidebar): a circle in the
  system's accent, or blue when the accent is near the lights' red, amber or green, or has no colour (graphite). On hover
  it shows a grid glyph, as the three show theirs.
- A click, or the pointer resting on it 0.6 s, shows a panel of five presets drawn as their shapes: side by side,
  stacked, three columns, one large and two stacked, a 2×2 grid. One the tabs cannot fill is disabled.
- A preset lays out the selected tab (`Workspace.apply(_:to:)`): with too few panes, the panes of the tabs after it join
  in their order; with too many, the extra ones become tabs right after it. Its focus stays when it can.
- It is a SwiftUI button drawn beside AppKit's three, which stay AppKit's (ADR on `WindowLights`): not one of them.

## Consequences

- It shows only where the sidebar's header is (docked or floating); not with the built-in tab bar or no sidebar.
- A kept entry (Favorites, Pinned) selected cannot be laid out: the light's presets are all disabled then.
- Not done: undo of a preset; the presets' keyboard shortcuts.
