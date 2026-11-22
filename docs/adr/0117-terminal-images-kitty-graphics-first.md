---
status: accepted
date: 2026-11-22
---

# Terminal images: the kitty graphics protocol first, kept by the core, drawn by the renderers

## Context

The owner's note n94 (2026-11-22): programs that ask whether the terminal shows images (`kitten icat`, yazi, chafa, timg,
ranger's previews) find Sunset does not. Roadmap 0010 asks for the kitty graphics protocol complete, then Sixel and iTerm2's
inline images. ADR-0010 has every request a program makes of the terminal under a policy: reading files, shared memory and
temporary files on a program's word is one.

## Decision

- **kitty's protocol first.** It is the one modern tools ask for first, and it answers queries: a program that asks gets
  `OK` for what Sunset shows, and an error for what it refuses, as kitty answers. Sixel and iTerm2's `File=` come after.
- **The core keeps images and their placements** (`SunsetCore`, platform-free): raw RGB and RGBA as sent; PNG kept encoded,
  its size read from its header, decoded by the renderer side through a seam (ImageIO on macOS). Each placement is anchored
  to the stable line it was put on, over the cells its pixels cover (the host tells the core a cell's size in pixels).
- **Only data sent in the escape itself** (`t=d`) is read. A file, a temporary file or shared memory (`t=f`, `t=t`, `t=s`)
  is refused (`EPERM`): Sunset never opens a path or a memory region because a program named it. Compression (`o=z`) is
  refused (`EINVAL`) until an inflater is part of the core.
- **A quota**: a terminal's images take at most 64 MiB (kitty's default is 320 MiB, for one window; Sunset keeps a terminal
  a tab, and a PNG is kept encoded, far smaller than its pixels). A new image that would not fit sends the oldest away
  first, with their placements; one larger than the quota is refused (`ENOSPC`). An image of more than 10,000 pixels a side
  is refused; at most 4,096 placements are kept, the oldest going first.
- **Replies** only when the program gave an image id, kept quiet by `q=1` (success) and `q=2` (always), as kitty.

## Consequences

- Programs that test for images find them; until the renderers draw them (the next step), they are placed but not shown.
- What is refused is said in the reply, so a program can fall back (to another medium, or to text).
- Animation, Unicode placeholders, relative placements and the delete forms beyond all and by id come later; each says so
  in roadmap 0010.
