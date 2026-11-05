# kitty (commit bdbf9f5, 2026-11-05; shallow clone read, nothing run)

| Claim | Evidence | Status |
|---|---|---|
| Child I/O and parsing run in one thread; rendering in another | `docs/performance.rst`; `kitty/child-monitor.c` (2.6k lines) | read, not probed |
| Parsing uses SIMD for plain text runs | `docs/performance.rst`; `kitty/simd-string.c`, `vt-parser.c` | read |
| Cells: `CPUCell` 12 bytes (codepoint or index, hyperlink id, multicell scale/width bits), `GPUCell` 20 bytes (fg, bg, decoration colour, sprite index, attrs) | `kitty/line.h` `static_assert`s | read |
| Glyphs are rasterised once into a GPU sprite atlas; per frame only cell data goes to the GPU | `docs/performance.rst`; `kitty/shaders/*.slang` (cell, graphics, border, trail, …) | read as names and docs |
| kitty throughput is about twice the next terminal on its own benchmark (ASCII 121.8, Unicode 105.0, CSI 59.8, images 251.6 MB/s on a Ryzen 7 PRO 5850U, X11) | `docs/performance.rst` table, kitty 0.33 | **vendor figure, not reproduced; Linux, not our machine** |
| Protocol documents to implement or consult: graphics, keyboard, text sizing (0.40+), wide-gamut colours, underlines, desktop notifications, file transfer, multiple cursors, pointer shapes, clipboard, color stack, unscroll, remote control | `docs/*.rst` | listed |
| Box-drawing and similar glyphs are drawn procedurally | `kitty/decorations.h` | read as a name only |

Open: kitty's actual text gamma/contrast handling (read `kitty/shaders` and `text_composition_strategy` docs), its graphics storage quotas and file-read restrictions (security policy input), its reflow algorithm, how it pages scrollback (`history.c`).
