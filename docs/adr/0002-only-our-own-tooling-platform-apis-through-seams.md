---
status: proposed
date: 2026-11-05
---

# 0002 — Only our own tooling; platform APIs only through seams

## Context

Owner: depend only on our own tooling, using Aemi or promoting to another package when it makes sense, reusing the whole family for every feature we need.

## Proposal

- Libraries: TerminalKit and the Aemi family and other g-cqd packages only. Generic pieces (grapheme/width/bidi, colour, compression and PNG, PTY, fonts, GPU abstraction) are promoted into new or existing Aemi packages when a second consumer is plausible.
- Platform APIs (libc; Metal, CoreText, CoreGraphics, AppKit; the PTY, Vulkan loader, Wayland/X11, fontconfig discovery on Linux) are *not* dependencies and are reached only through a seam.
- Apple/swiftlang packages (swift-system, swift-collections, swift-syntax, swift-crypto, swift-subprocess, swift-argument-parser) only where Aemi already pins them.

## Open (needs the owner)

Are platform libraries allowed as stated? Are Aemi's existing Apple pins acceptable? Is fontconfig discovery on Linux acceptable, or do we scan font directories ourselves?
