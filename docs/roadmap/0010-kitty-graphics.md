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
| B | Drawn: the CPU renderer (the reference) and Metal; PNG decoded through a seam (ImageIO on macOS), once, cached by image; layers above and below the text (`z`); a placement's pixels clipped to its cells | done 2026-11-22 (`CPURendererImageTests`, `MetalImageDifferentialTests`, `ImageIODecoderTests`; `kitten icat` draws a PNG). Not done: kitty's middle layer: kitty draws `z` < 0 over coloured cell backgrounds and under the text, and only `z` below −1,073,741,824 under those backgrounds; Sunset draws every `z` < 0 under them (step C); images are not drawn again at a new size when the font changes; the image table starts again past 128 MiB rather than evicting one image |
| C | What step A left: deletes by cell, row, column, `z` and range; source rectangles (`x`, `y`, `w`, `h`); offsets within a cell (`X`, `Y`); the alternate screen's own images; checked against kitty as the oracle | done 2026-11-23 (`KittyPlacementTests`, `CPURendererImageLayersTests`, `MetalImageDifferentialTests`): every delete kitty has but by number (`n`: image numbers `I` are not supported yet), capitals freeing images left without a placement, a delete ending an upload; the quota taking unshown images first; parts and offsets; kitty's three layers (the middle one: a row's backgrounds, then images, then text); each screen its placements (images shared, one quota). Not done: checked against kitty itself (it would draw on the owner's screen); image numbers (`I`); on the alternate screen an image does not move when that screen scrolls (its lines are not counted) |
| D | Compression (`o=z`): an inflater in the core (Compression through a seam). Needed for most pictures: `kitten icat` sends every JPEG as zlib-compressed RGB | done 2026-11-22 (`KittyCompressionTests`, `ZlibInflaterTests`; `kitten icat` draws a JPEG). The core keeps the policy (never past the size raw pixels must have, nor the quota for a PNG; refused past the quota before any work); the host inflates (`ZlibInflater`: header, Compression, Adler-32). Not measured: inflating speed |
| E | Unicode placeholders; animation | not-started |
| F | Sixel; iTerm2's inline images (OSC 1337 `File=`) | not-started |

Refused by ADR-0117, and answered so (`EPERM`): images read from a file, a temporary file or shared memory.

Not done: C, E, F.
