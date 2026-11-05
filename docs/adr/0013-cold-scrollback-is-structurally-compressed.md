---
status: accepted
date: 2026-11-05
---

# 0013 — Cold scrollback is stored structurally, not as compressed raw pages

## Context

Ghostty LZ4-compresses cold pages and decommits their memory (`terminal/compress/Page.zig`); WezTerm keeps lines as text plus attribute clusters; kitty keeps a text ring for the pager. None combines structure with lazy per-row decoding.

## Proposal

Rows that have scrolled out of the hot region are re-encoded as UTF-8 text + style runs (deduplicated styles) + wrap/prompt flags, in immutable segments; decoded per row on demand (display, search, selection, reflow). Physical memory of retired hot pages is returned to the OS (`MADV_FREE_REUSABLE` on Darwin, `MADV_DONTNEED` on Linux, as Ghostty plans).

## Open

Bytes per cell and decode µs per row on the ADR-0021 corpus (139 agent transcripts, 225 MB, local) for raw, LZ4-of-page and structural; and on truecolor-heavy synthetic output, where structure may lose. If LZ4-of-page wins on both, this ADR is rejected.

## Evidence so far (research/kernels-study.md §§2, 7b)

Synthetic pages from real text: structural 0.45 B/cell vs LZ4_RAW of raw pages 0.82 (platform LZ4, 4.1 GB/s decode). Live encoder on an 8.5 MiB coloured log: 57 B per row (5.9% of a 120-cell hot row), cold walk 36 ns/row, encode 0.1–0.45 µs/row single-threaded and naive. Real transcript corpus and truecolor output still open.

## Evidence, real text (2026-11-05, `Benchmarks/Probes/ColdHistoryProbe`; sizes are deterministic, independent of machine load)

Corpus: the owner's own ask sessions on this machine (private; 146 files, 210 MB of JSONL), text fields rendered the way ask draws them (user `> ` bold cyan, assistant plain, tool output dim, code fences yellow; `probes/gen-corpus.py`), streamed through the VT model at 120 columns. Only aggregate numbers are recorded here. Rows that left a 1,000-row hot ring:

| Encoding of evicted rows | B/row (16 MiB input, 143,294 rows) | B/row (64 MiB, 326,363 rows) | % of raw (64 MiB) |
|---|---|---|---|
| raw 8-byte cells | 960 | 960 | 100 |
| raw rows + LZ4_RAW, 1 MiB pages (platform) | 97.8 | 100.6 | 10.5 |
| raw rows + LZFSE | 43.1 | 44.0 | 4.6 |
| raw rows + ZLIB | 42.4 | 43.1 | 4.5 |
| **structural** (text + style runs) | **58.8** | **59.8** | **6.2** |
| **structural + LZ4_RAW** | **26.8** | **27.3** | **2.8** |
| structural + ZLIB | 18.2 | 18.3 | 1.9 |

Reading: structural alone is 1.7× smaller than LZ4 of raw pages (which is what Ghostty's scheme is, modulo its page layout), structural + LZ4 is **3.7×** smaller, and only the slow compressors (LZFSE, ZLIB at ~0.03 and 0.02 GB/s earlier) beat structural alone. The ratios are the same at 16 and 64 MiB.

Limits: styles are role-based and synthetic (no truecolor gradients, where structure may lose; no hyperlinks), the text is prose, code and tool output rather than a build log or `cat` of binary-ish data, and Ghostty's actual page compression was not run (its LZ4 over its own page layout may differ from LZ4 over my 960-byte rows).

## Decision

Cold history is the structural form; an LZ4 layer over cold segments is optional and measured on top (roadmap 0015, own LZ4 kernel). Truecolor-heavy streams are re-probed before the format is frozen.
