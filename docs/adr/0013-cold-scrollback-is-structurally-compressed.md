---
status: proposed
date: 2026-11-05
---

# 0013 — Cold scrollback is stored structurally, not as compressed raw pages

## Context

Ghostty LZ4-compresses cold pages and decommits their memory (`terminal/compress/Page.zig`); WezTerm keeps lines as text plus attribute clusters; kitty keeps a text ring for the pager. None combines structure with lazy per-row decoding.

## Proposal

Rows that have scrolled out of the hot region are re-encoded as UTF-8 text + style runs (deduplicated styles) + wrap/prompt flags, in immutable segments; decoded per row on demand (display, search, selection, reflow). Physical memory of retired hot pages is returned to the OS (`MADV_FREE_REUSABLE` on Darwin, `MADV_DONTNEED` on Linux, as Ghostty plans).

## Open

Bytes per cell and decode µs per row on the ADR-0021 corpus (139 agent transcripts, 225 MB, local) for raw, LZ4-of-page and structural; and on truecolor-heavy synthetic output, where structure may lose. If LZ4-of-page wins on both, this ADR is rejected.
