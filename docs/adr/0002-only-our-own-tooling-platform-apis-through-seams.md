---
status: accepted
date: 2026-11-05
---

# 0002 — Our own tooling (and approved Apple/swiftlang packages); platform APIs only through seams

## Context

Owner: depend only on our own tooling, using Aemi or promoting to another package when it makes sense, reusing the whole family for every feature we need.

## Proposal

- Libraries: TerminalKit and the Aemi family and other g-cqd packages only. Generic pieces (grapheme/width/bidi, colour, compression and PNG, PTY, fonts, GPU abstraction) are promoted into new or existing Aemi packages when a second consumer is plausible.
- Platform APIs (libc; Metal, CoreText, CoreGraphics, AppKit; the PTY, Vulkan loader, Wayland/X11, fontconfig discovery on Linux) are *not* dependencies and are reached only through a seam.
- Apple/swiftlang packages (swift-system, swift-collections, swift-syntax, swift-crypto, swift-subprocess, swift-argument-parser) only where Aemi already pins them.

## Open (needs the owner)

Are platform libraries allowed as stated? Are Aemi's existing Apple pins acceptable? Is fontconfig discovery on Linux acceptable, or do we scan font directories ourselves?

## Decision (owner, 2026-11-05)

"Sunset can be bound to any package from g-cqd or aemi-studio, and on approval to apple or swiftlang ones."

- **Free to depend on**: any package of the g-cqd and Aemi-Studio organisations (TerminalKit, the Aemi family, the rest), pinned by revision as the family does. Used so far: `TerminalKitText` (display widths) by revision `5966813`.
- **On approval, one at a time**: Apple and swiftlang packages (swift-system, swift-collections, swift-crypto, swift-subprocess, ...), including the ones Aemi already pins transitively; ask before adding one as a direct dependency. (Resolving TerminalKit pulls swift-system and swift-collections transitively through Aemi: not a direct dependency of ours, and not used.)
- Platform APIs stay behind seams as proposed above; the owner's answer did not cover them or fontconfig on Linux, so those two questions remain open.
- Everything else in the proposal stands: generic pieces are promoted into Aemi when a second consumer is plausible; other emulators are oracles run as processes, never linked (ADR-0004).
