# Sunset

Sunset is a terminal emulator written in Swift on our own tooling: kitty-graphics compatible and modern-protocol complete, built for performance, safety, resilience, reliability and security,
with colour accuracy, GPU acceleration and good typography as first-class goals. macOS first; Linux is a real target. (`Aemi*` names are for dependencies, never end products; the name was chosen by the owner on 2026-11-05, ADR-0011.)

**Status: design and research. No code yet.**

## Start here

- [White paper](docs/WHITE-PAPER.md): the principles and bars. Paste at the start of every iteration.
- [Design](docs/design/0001-architecture.md): the layers, from a platform-free core to the renderer and app.
- [ADRs](docs/adr): one decision per file. [Roadmap](docs/roadmap): one file per unit of work. [Diary](docs/diary): probe history.
- [Research](docs/research): kitty, other terminals, protocols, colour, typography, and the [full investigation snapshot](docs/research/2026-11-05-investigation.md).
- [AGENTS.md](AGENTS.md), [Contributing](CONTRIBUTING.md), [Security](SECURITY.md), [License](LICENSE) (MIT).

## Goals

| Goal | What it means here |
|---|---|
| Compatibility | xterm/DEC core, kitty graphics (all transmission modes, animation, Unicode placeholders), kitty keyboard, text sizing (OSC 66), OSC 8/52/133, synchronized output, Sixel and iTerm2 images |
| Performance | a parser at or above the best measured emulators on the same harness; a renderer whose idle cost is ~0; key-to-screen latency measured |
| Safety, security | memory-safe parser, bounded memory, policy for every untrusted action (clipboard, file reads, links, paste), fuzzed |
| Resilience, reliability | the parser cannot fail; GPU loss recovers; session byte streams replay deterministically |
| Colour | a tested pipeline: palette/sRGB/P3 in, linear-light blending, display space out; contrast enforcement; follows system appearance |
| GPU | glyph atlas and instanced cells on Metal (macOS) and Vulkan (Linux), a CPU reference renderer |
| Typography | ligatures, fallback, colour emoji, variable fonts, our own OpenType shaping and rasterising (required on Linux), text sizing |
| Platforms | macOS first; Linux a target from the start (a platform-free core behind seams) |

## Dependencies

Only our own tooling: [TerminalKit](https://github.com/g-cqd/TerminalKit) and the Aemi family, with generic pieces promoted into Aemi. Platform APIs are reached through seams.
Other terminals and emulator libraries are *test oracles run as separate processes*, never linked. See [ADR-0002](docs/adr/0002-only-our-own-tooling-platform-apis-through-seams.md) (accepted: g-cqd and Aemi-Studio packages freely, Apple and swiftlang ones on approval).

## Relationship to TerminalUI

[TerminalUI](https://github.com/g-cqd/TerminalUI) is the SwiftUI-like framework for programs that run *in* a terminal. This is the program that hosts them. They help each other: this terminal's headless
emulator is TerminalUI's oracle for "bytes → screen", and TerminalUI's frame output is this terminal's best fuzz corpus.
