---
status: in-progress
blocked-by: nothing
date: 2026-11-22
---

# 0010 — Images in the terminal: kitty graphics, then Sixel and iTerm2's

The owner's note n94 (2026-11-22): programs that show images in a terminal (`kitten icat`, yazi, chafa, timg) find Sunset
does not. ADR-0117 decides how: kitty's protocol first, kept by the core, drawn by the renderers; only data in the escape
read; a quota.

| Step | What | Status |
|---|---|---|
| A | The core: images sent in the escape (RGB, RGBA, PNG kept encoded), in chunks; placed at the cursor over the cells they cover, on their stable line, the cursor moved after them (`C=1` not); deleted (all, by image, by placement); queried; answered as kitty answers (`q=1`, `q=2`); a quota (64 MiB a terminal), a side limit (10,000 px), a placement limit (4,096); a full reset takes the images; a cell's size in pixels from the host, told to programs (CSI 14 t, 16 t; the PTY's window size) | done 2026-11-22 (`KittyGraphicsTests`, `CellPixelSizeTests`); not drawn yet |
| B | Drawn: the CPU renderer (the reference) and Metal; PNG decoded through a seam (ImageIO on macOS), once, cached by image; layers above and below the text (`z`); a placement's pixels clipped to its cells | not-started |
| C | What step A left: deletes by cell, row, column, `z` and range; source rectangles (`x`, `y`, `w`, `h`); offsets within a cell (`X`, `Y`); the alternate screen's own images; checked against kitty as the oracle | not-started |
| D | Compression (`o=z`): an inflater in the core (Compression through a seam) | not-started |
| E | Unicode placeholders; animation | not-started |
| F | Sixel; iTerm2's inline images (OSC 1337 `File=`) | not-started |

Refused by ADR-0117, and answered so (`EPERM`): images read from a file, a temporary file or shared memory.

Not done: B to F. Until B, programs are told images work and nothing shows.
