# Design 0001 — Layers

Intended design; why is in the ADRs; measurements are in the diary. **Nothing is built.**

```
 shell      AppKit app (macOS)  ·  Wayland/X11 app (Linux)     tabs, splits, selection, search, IME, themes
 renderer   CPU reference · Metal · Vulkan                      glyph atlas, instanced cells, images, damage, colour out
 fonts      parse · shape · rasterise (ours); CoreText = oracle  fallback, ligatures, variable, colour emoji, text sizing
 host       PTY + process behind a seam (Darwin, Linux)         reader thread with backpressure, resize, signals
 core       VT parser · screen · scrollback · modes · replies   protocols: kitty graphics/keyboard, OSC 8/52/66/133, sync output, mouse, Sixel, iTerm2
 colour     palette → working space → linear blend → display    contrast, system appearance
```

- **Core** is pure Swift, platform-free, headless and bounded: a byte stream and a size in; cells, cursor, modes, images and replies out. The headless API (spawn, keys, resize, snapshot) is a product.
- **Parser**: a state machine over `RawSpan<UInt8>`, a fast path for printable runs using Aemi's byte kernels (kitty does this with SIMD in `simd-string.c`; unmeasured here). Every input has a defined outcome.
- **Screen**: pages of rows, wrap flags, scrollback ring, alternate screen, reflow on resize, semantic prompt marks (OSC 133). Cell colour storage per ADR-0005 (pending probe).
- **Threads** (kitty's model): PTY read and parse in one thread; rendering on another; a watchdog; a slow renderer never stalls the reader.
- **Renderer**: per-frame upload is cell data only; glyphs are rasterised once into an atlas; images are textures; presenting is damage-aware and paced to the display.
- **Linux**: the core and host compile with no Darwin; renderer and shell are backends behind seams.
- **Control**: a protobuf (AemiProtobuf) remote-control protocol on a unix socket, with peer-credential authentication; the equivalent of kitty's `@` interface.

## Verification ladder (white paper §3, §9)

byte-exact tests → oracle model → real-emulator differential tests (kitty, ghostty, wezterm, Terminal.app, SwiftTerm, libghostty as processes) → `vttest`, `esctest`, `vtebench` → fuzzing and session replay.

## Performance architecture (hypotheses from research/performance-study.md; each gated by a probe, roadmap 0002 and 0014)

- Hot cell ≤ 8 bytes, page-local reference-counted styles, offsets not pointers, bitmap-allocated graphemes (ADR-0012).
- Cold scrollback re-encoded structurally and decoded per row; retired pages returned to the OS (ADR-0013).
- Reader owns the screen; the renderer never takes a lock: frame-wanted flag, dirty rows published to a triple buffer (ADR-0014).
- Parse straight into cells in vector-scanned runs, no intermediate action objects; SIMD path differentially tested against a scalar path.
- GPU reads cell memory directly on unified-memory Macs; side buffer for shaped rows (ADR-0015, a bet).
- Frames latched late against vsync; nothing scheduled when nothing changed (ADR-0016).
- Bounded everything; synchronized output has a timeout.
