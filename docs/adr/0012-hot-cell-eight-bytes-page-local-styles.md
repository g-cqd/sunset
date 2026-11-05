---
status: proposed
date: 2026-11-05
---

# 0012 — A hot cell is at most 8 bytes, with page-local reference-counted styles

## Context

Read (research/performance-study.md): Ghostty's cell is 8 bytes (codepoint or an inline background colour, a 16-bit page-local style id, small flags), kitty's is 32 and Alacritty's at most 24. TerminalKit's `PackedCell` is 16 bytes with a process-wide append-only style table (fine for ask, wrong for an emulator; ADR-0005).

## Proposal

- Hot cell ≤ 8 bytes; a background-only cell carries its colour inline (no style entry); a style id indexes a per-page, reference-counted, bounded set; a full set triggers a page split, never a global table.
- Row flags may be false positives but never false negatives (`styled`, `grapheme`, `hyperlink`, prompt, placeholder); fast paths when clear.
- Grapheme and string data live in per-page bitmap-allocated areas addressed by offsets, so a page can be copied, compressed and handed to the GPU as bytes (ADR-0015).
- Goal beyond the reference design: fewer bytes per *useful* cell through ADR-0013, not by shrinking the hot cell below what is random-access.

## Open (probe T0, roadmap 0002)

Time and bytes per cell on ASCII, SGR-dense and truecolor-gradient streams for: 8 B + page styles, 16 B + page styles, inline colours (kitty-like), interned global table. Refines and, if confirmed, supersedes ADR-0005.

## Evidence so far (research/kernels-study.md §7b, probes/vtmodel2.swift; noisy machine)

8 / 16 / 32-byte cells in one Swift state machine: scrolling 5.2 / 7.6 / 19.9 ms/MiB (quiet window), ratios stable under load; SGR-dense stream 5.7 / 5.7 / 4.6 (inline colours skip a style lookup). Supports the 8-byte hot cell; shows the style lookup is the cost to engineer (cache last style; page-local table). Not yet probed: page-local tables with page splits, truecolor gradients over many pages.
