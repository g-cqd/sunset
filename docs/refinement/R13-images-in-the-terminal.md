# R13 — Images in the terminal: the design session (roadmap 0010, 0026 T-9, t183)

Status: **answered by the owner 2026-11-22** (below). Nothing is built.
The owner, 2026-11-21: "it seems the terminal for sunset still can't show images, even though ask can work with showing pictures in ask".
R9 set the process: images get a design session of their own, then kitty graphics.

## Why nothing shows today (read in the source, 2026-11-22)

1. **Sunset drops every APC string.** `Screen.stringStart` sends every kind to `oscStart`, which collects only `.osc`
   (`Screen+OSC.swift`): a kitty graphics command (`ESC _ G … ESC \`) is parsed and thrown away, and no answer is written.
2. **ask never asks Sunset.** ask sends its graphics query only where `TERM=xterm-kitty`, `TERM=xterm-ghostty` or `TERM_PROGRAM=ghostty`
   (`AskTUI/TerminalGraphics.mayDraw`); Sunset sets `TERM_PROGRAM=sunset`, `TERM=xterm-256color`. Even with graphics built, ask needs
   one line of its own changed, and that change must wait until Sunset answers `OK` truthfully: placeholder cells that a terminal does
   not draw show as unknown characters.

## What ask needs, exactly (the first slice)

ask (TerminalKit's `GraphicsEncoder`, ask's `ImagePlacement`) uses a narrow part of the protocol:

| Command | Keys | What Sunset must do |
|---|---|---|
| Query | `a=q f=24 t=d i=<id> s=1 v=1` + 3 bytes | answer `ESC _ G i=<id>;OK ESC \` without keeping anything |
| Transmit | `a=t f=100 t=d i=<id> q=2`, chunked (`m=1` … `m=0`), base64 | keep a PNG under `id`, quietly |
| Virtual placement | `a=p U=1 i=<id> c=<cols> r=<rows> q=2` | remember the image's grid size, place nothing |
| Delete | `a=d d=I i=<id> q=2` | forget the image and its data |
| Placeholder cells | `U+10EEEE` + a row mark + a column mark, foreground colour = the id's low 24 bits | draw that piece of the image in the cell |

Placeholders are text to the screen: they scroll, wrap, reflow, clear and are copied as any cell is, which is why ask chose them and
why they cost the screen nothing new. They arrive as cluster cells (the scalar and its two marks).

## The proposed design

- **Core (platform-free):** an APC collector beside the OSC one, only for strings starting with `G`, bounded by the parser's 1 MiB string
  limit and kitty's 4096-byte chunk; a `GraphicsCommand` reader (keys and base64); an image store keyed by id holding the encoded bytes,
  with a quota (kitty's is 320 MB per screen as I remember its documentation, not re-read today; proposed lower, Q3); replies through the existing `ReplyWriter`. Decoding is not in the core.
- **Decoding at the seam:** PNG (and RGB/RGBA raw) to pixels in `SunsetRenderMac` through ImageIO, off the main thread, once per image,
  bounded in pixels (Q3). A decode failure answers an error, as kitty does.
- **Drawing:** in the GPU compositor, an image is one texture; a placeholder cell is one more instance sampling its piece (row and column
  from the marks, the image's grid from its virtual placement). The CPU reference renderer draws the same, as the oracle for the GPU's
  pixels. **Cost when unused:** the only new work on the text path is a test of a cluster cell's base scalar for `U+10EEEE`; it is
  measured before and after on the existing benchmark (R9's first requirement for images).
- **Policy (ADR-0010):** direct transmission only in the first slice; file, temporary file and shared memory refused with an error (they
  read the person's disk or memory on a program's say-so; Q4). Images are per screen, freed with it; the alternate screen keeps its own.
- **ask:** once Sunset answers `OK`, `TerminalGraphics.mayDraw` accepts `TERM_PROGRAM=sunset`, tested both ways.
- **Oracles:** kitty and Ghostty run as processes on the same byte streams (ask's recorded output of a picture), compared by screenshot.

## Later slices (not in the first)

Placements at the cursor (`a=T`/`a=p` without `U=1`), z-index, cropping and offsets; animation; compressed payloads (`o=z`); Sixel and
iTerm2's OSC 1337 inline images; `a=q` capability details; the deletion kinds other than `d=i`/`d=I`.

## Questions for the owner

- **Q1** The first slice as above (exactly what ask uses), or kitty's whole protocol before anything ships?
- **Q2** Its place in the order: now, ahead of R9's other terminal items (which wait behind the pane work), or where R9 put it?
- **Q3** Limits: memory for images per terminal (proposed 64 MB of encoded data and 64 megapixels decoded, 256 MB of pixels), and what happens past it
  (kitty evicts the oldest).
- **Q4** File, temporary-file and shared-memory transmission: refused (proposed), or allowed for local programs with a setting?
- **Q5** Sixel and iTerm2 images: wanted at all, and when?

## The owner's answers (2026-11-22)

| Question | Answer |
| --- | --- |
| Q1 the first slice | **The whole kitty graphics protocol first**, not only what ask uses |
| Q2 its place in the order | not answered separately; asked for now (the owner raised it on 2026-11-21) |
| Q3 limits | not answered: the proposal (64 MB encoded, 64 megapixels decoded per terminal, oldest evicted) stands as a default to confirm |
| Q4 file, temporary-file and shared-memory transmission | not answered: refused until answered (ADR-0010's rule: no untrusted action without a policy) |
| Q5 Sixel and iTerm2 images | not answered |

So "Later slices" above become part of the first build, except Sixel and iTerm2's images. ask's change (`TERM_PROGRAM=sunset`) still
waits until Sunset answers the query truthfully.

