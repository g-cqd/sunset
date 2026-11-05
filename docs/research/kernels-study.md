# Extending Aemi's kernel collection for Sunset, TerminalUI and TerminalKit

Written 2026-11-05 at the owner's request ("study extending our assembly/C/ARM/kernel collection in aemi if relevant, for example LZ4"). Aemi itself is **unchanged**; these are findings and proposals to hand to Aemi as its own ADRs and roadmap entries when work starts.
Labels: **[read]** source/docs, **[probed]** I ran it (probes in `probes/`, Apple M3, macOS 27.0.1, `clang -Os`), **[unverified]**.

## 1. What Aemi's kernel tier is today [read]

- **`CAemiKernels`** (3.9k lines of C) behind the strict-memory-safe Swift facade **`AemiKernels`**; **`CAemiCPU`** resolves the CPU feature set once (NEON, CRC32, PMULL, AES, SHA2/3/512, DotProd, I8MM, BF16, SVE/SVE2/SME, DIT, SB; x86 SSE2…AVX-512; Rosetta flag).
- **Intrinsics, not assembly**: a search found no `.S`/`.s` file; inline `asm` appears only in `CAemiArgon2/adf_crypto_secure.c` and `CAemiCPU/adf_cpu_timing.c`. Every kernel has a portable `_scalar` reference and per-ISA backends (`_neon`, `_sse2`, `_avx2`, and x86 AVX-512 gated), runtime-dispatched.
- **Existing kernels**: ASCII fold; JSON string-stop scan; first-of-5-bytes; first byte in/not in a nibble-table set (Teddy-style); positions of either of two bytes; first non-ASCII; first disallowed text byte; first control-or-5-literals; UTF-8 validation; CRC-32C; bit count; UTF-16→ASCII prefix; Hamming; ISO-8601; byte search; pair-set find/candidates; Base64 (blocks and lines); hex; percent coding; count-in-set; substring find.
- **Discipline (aemi ADR-0008/0011/0021/0027)**: measured at the real `-Os` flags with a harness that can fail (an earlier probe was wrong, and the ADR says how); differential tests against scalar at every length 0–65/300 × 64 alignments; guard-page tests (`GuardedBytes`); exhaustive edge checks (41 M and 21 M cases); libFuzzer targets on macOS, Rosetta and Linux; ThreadSanitizer; **mutation testing of the checks themselves** (62 mutants, all killed); Linux arm64 and x86-64 in CI.
  Any new kernel for us inherits all of it, which is a large part of what a kernel costs.
- Known weakness, recorded by Aemi: the dispatcher's per-call cost on short inputs (`adf_kernels_isa()` plus a switch): about half of the NEON kernel's speed at 64 B (ADR-0011).

## 2. Probes run today [probed]

**(1) VT "stage 1": finding control bytes (`probes/vtscan.c`).** Streams of ~1 MiB, GB/s of input, best of 31, correctness: 0 mismatches against scalar (5 streams; lengths 0–299 × 64 offsets, random bytes).

| Stream | control bytes / KiB | scalar loop | Aemi `adf_index_of_control_or_any5`, called per run | bulk NEON positions (16 B/step) | bulk NEON (64 B/step + all-clear skip) |
|---|---|---|---|---|---|
| plain 80-col text | 12.6 | 1.04 | 3.31 | **10.72** | 9.78 |
| SGR truecolor dense | 42.3 | 0.78 | 1.55 | **7.27** | 6.35 |
| TUI cursor moves | 69.3 | 0.56 | 0.74 | **7.51** | 6.41 |
| `ls --color`-like | 63.0 | 0.68 | 0.85 | **5.76** | 5.23 |
| UTF-8 heavy | 8.5 | 0.88 | 4.20 | 7.51 | **9.78** |

Reading: the existing kernel is excellent on long runs but loses 2.3×–9× on the short runs that real terminal streams have, because a call per run pays dispatch and setup (the ADR-0011 weakness, now measured for this use). A **bulk "positions of every C0/DEL byte" kernel**
(simdjson-style stage 1: classify a whole chunk once, then the state machine walks positions and copies printable runs between them) is 5–10 GB/s on every stream, **2–10× the per-run use**.
**Caution, important:** kitty's own benchmark table reports end-to-end throughput of ~60–250 MB/s (vendor figure, different CPU, includes screen updates). Scanning at 5–10 GB/s is two orders of magnitude above that, so **scanning is not the bottleneck of a terminal**; it is the state machine, the cell writes and scrolling.
Do not over-invest in scanning kernels; the next probes matter more.

**(2a) ASCII bytes → 8-byte cells (`probes/cells.c`).** NEON 3.3 GB/s of input (26 GB/s of cell output) vs scalar-at-`-Os` 1.9 GB/s: 1.7×; for a 120-cell row 37 ns vs 61 ns. Modest because the scalar path is already near store bandwidth at this width; the real gain will come from fusing it with the width/wrap logic, not from this kernel alone.

**(2b) First differing 8-byte cell between two grids (front/back buffer diff).** After fixing a hoisting flaw in my own first run:

| Compared | scalar word loop | NEON 64 B/step | libc `memcmp` (equality only) |
|---|---|---|---|
| one 120-cell row (960 B) | 17.5 GB/s | **44.0** | 31.0 |
| 120×40 grid (38.4 KB, L1/L2-resident) | 19.1 | **54.2** | 34.4 |
| 300×80 grid (192 KB) | 19.2 | **37.0** | 34.5 |

Reading: a purpose-built mismatch-index kernel is 2.3–2.8× the obvious loop and 1.1–1.6× Apple's `memcmp`, and unlike `memcmp` it returns *where*. 0.15 ns per 8-byte cell for a 120×40 grid vs TerminalKit's measured 2.3 ns per unchanged 16-byte cell (ADR-0021 there; different build, load and what it includes, so **not** a like-for-like ratio; the real figure needs the kernel inside `DiffRenderer`). Cheap, general, promising for TerminalKit and TerminalUI idle cost.

**(3) Compression of terminal pages (`probes/lz.c`), using the platform's `libcompression` as the baseline to beat.** Synthetic pages: real text (ask's 600 KB of Swift, wrapped to 120 columns, 12,958 rows) laid out as 8-byte cells with synthetic style ids; **not** the ADR-0021 transcript corpus,
and source code is blank-heavy, so absolute ratios flatter everything; **relative** ratios are the signal:

| Encoding of the same pages | bytes per cell | % of raw | compress | decompress |
|---|---|---|---|---|
| raw 8-byte cells | 8.00 | 100 | – | – |
| **LZ4_RAW** (platform) of 1 MiB raw pages | 0.82 | 10.3 | 1.52 GB/s | **4.08 GB/s** |
| LZFSE of raw | 0.38 | 4.7 | 0.03 GB/s | 3.18 GB/s |
| ZLIB of raw | 0.40 | 5.0 | 0.02 GB/s | 0.22 GB/s |
| **structural** (trimmed UTF-8 text + style runs, no compressor) | **0.45** | **5.6** | trivial | trivial (linear walk) |
| structural + LZ4_RAW | 0.19 | – | – | – |
| structural + ZLIB | 0.12 | – | – | – |

Reading: on this corpus the structural form is **1.8× smaller than LZ4 of raw pages** and needs no compressor, supporting ADR-0013's hypothesis; LZFSE matches it only at 1/50th of the compression speed. Putting LZ4 *behind* the structural encoding gets to 0.19 B/cell.
So LZ4 is useful in Sunset, but **after** the structural encoding, not instead of it, which changes what the LZ4 kernel is for: compressing small, already-dense byte streams (and graphics/snapshots), not raw cell pages. To be re-run on the real transcript corpus and on truecolor-heavy synthetic output where structure may lose.

## 3. Where kernels would pay for Sunset / TerminalUI / TerminalKit [analysis; probes decide]

Ranked by "end-to-end effect × reuse", with the evidence each needs. Existing Aemi coverage marked.

| Candidate kernel | Used by | Why | Evidence so far | Priority |
|---|---|---|---|---|
| **Mismatch index over cell arrays** (first/last differing 8/16-byte unit; run of equal units) | TerminalKit `DiffRenderer`, TerminalUI damage, Sunset dirty rows | idle cost and partial updates | probed: 2.3–2.8× scalar, 1.1–1.6× memcmp | high |
| **Cell write paths**: ASCII-run→cells with style/width, row fill/erase with a cell pattern, row blits for scroll | Sunset core | the actual bottleneck is cell writes and scrolling, not scanning | (2a) only the expand piece; needs fusion probe | high |
| **Bulk C0/DEL positions** (stage 1) | Sunset parser | 2–10× the per-run scan on real streams | probed | medium (scanning is not the bottleneck) |
| **UTF-8 → scalars until control; scalars → UTF-8** | Sunset parser, structural encoding, text extraction | Ghostty does this in SIMD (`simd/vt.cpp`); none in Aemi today (only validation) | not probed | medium |
| **LZ4 block (compress, decompress)** | Sunset cold history/snapshots, images cache, session recording | platform LZ4_RAW is the bar: 4.1 GB/s decode, 1.5 GB/s encode (this machine) | baselined; our kernel not written | medium; own implementation from the public block format (no dependency), exists on Linux too (libcompression does not) |
| **Structural row encoder/decoder** (text + style runs + flags) | Sunset scrollback, search | 1.8× smaller than LZ4(raw) on the synthetic corpus | probed | high (it is a codec, with NEON helpers for run detection) |
| **Style-run boundaries over strided fields** | structural encoder, GPU run building | find where a 16-bit field changes in 8-byte cells | not probed | medium |
| **Row hash** (AES-based or multiply-mix, 16–32 GB/s class) | TerminalKit scroll detection (ADR-0022 there), TerminalUI, Sunset reflow | row hashes at memory speed; Apple CPUs have AES instructions | not probed | medium |
| **inflate/deflate + Adler-32 + CRC-32 (ISO)** | kitty graphics (`o=z`), PNG, gzip | needed for compatibility; CRC-32 differs from Aemi's CRC-32C but the ARM CRC32 instruction family covers both | none | required, not for speed alone |
| **PNG unfilter (Sub/Up/Avg/Paeth), RGBA↔BGRA, premultiply** | kitty graphics f=100/32/24, CPU renderer | well-known NEON wins | none | medium |
| **Alpha blend / gamma-correct text-mask blend / sRGB↔linear** | Sunset CPU reference renderer, colour tests | colour accuracy needs exact arithmetic; the CPU renderer is the oracle | none | later |
| **Coverage accumulation (area/cover prefix-sum → 8-bit)** | Sunset font rasteriser | the core loop of a scanline rasteriser | none | with the font stack |
| Base64, hex, percent, find, fold, crc32c | kitty graphics payloads, search, hyperlinks | **already in Aemi** | read | done |

## 4. Assembly, intrinsics, or neither (a rule, to be adopted by Aemi as an ADR)

1. **Neither is the default: libc/system first when it already wins.** `memcmp`/`memmove`/`memset_pattern` are tuned assembly (probed: `memcmp` is within 1.1–1.6× of the best kernel I wrote); wrapping them in a new kernel is a regression in maintenance.
2. **C with intrinsics** for everything else, as Aemi does: per-function target attributes, runtime dispatch, scalar oracle, the full ADR-0027 check stack.
3. **Hand assembly only if** a measured gain over the best intrinsics version, at Aemi's real `-Os` flags, exceeds a threshold fixed *before* looking (suggestion: 20% on the harness that can fail), in a loop that is hot in an end-to-end profile; and it carries the same checks plus a guarded fallback.
   Realistic candidates: an LZ4 decompression inner loop (overlapping match copy), an inflate decode loop, crypto. A Swift package can carry `.S` files only through a C target (SwiftPM compiles them), and inline `asm` already exists in two Aemi files, so there is a path; the cost is per-ISA and per-OS duplication, hence the high bar.
4. **Streaming SVE/SME** (M4+, `ADF_CPU_SME` is already detected): this machine reports `FEAT_SME: 0`, so nothing to measure here; revisit when hardware is available.
5. **Dispatch cost is part of the kernel**: new kernels take whole buffers (bulk APIs), not one call per run, and expose a resolved function pointer or an inlinable header for hot callers. This is the lesson of probe (1).
6. **Linux and x86**: every new kernel keeps the x86 SSE/AVX2 tiers (or documents a scalar-only tier) and the Linux CI, since Sunset targets Linux (ADR-0001 here).

## 5. Proposed work (handed to Aemi as separate entries; here as Sunset roadmap 0015)

1. Aemi ADR: kernel-selection rule (§4), including "libc first".
2. `adf_mismatch_index` family (8/16-byte units, first/last, equal-run length), then adopt it in TerminalKit's `DiffRenderer` and measure `ask` idle (needs ask roadmap/TerminalUI 0007 baseline first).
3. `adf_c0_positions` (stage 1) and `adf_utf8_decode_until_control`; a differential test of the SIMD path against scalar, as Ghostty does.
4. LZ4 block codec (own), benchmarked against `libcompression` LZ4_RAW (platform baseline above) and Ghostty/kitty-class results where available; after the structural encoder exists.
5. inflate + Adler-32 + CRC-32 + PNG unfilter for kitty graphics (`AemiCompression`/`AemiImage` promotions, Sunset roadmap 0001).
6. Row hash.
Each: red tests first, scalar oracle, guard-page, exhaustive, fuzz, mutation; promoted into Aemi, pinned by dependents.

## 6. Not known

- Real-corpus compression ratios (ADR-0021's 139 transcripts) and truecolor-heavy behaviour; whether LZ4-after-structural is worth its CPU.
- The cost of the state machine and cell writes in a Swift parser (the true bottleneck): needs the T0 parser probe (roadmap 0002) before any more kernel work is justified.
- How the numbers move on other Apple chips (M1/M2/M4) and x86; this is an M3.
- Whether Swift's `Span` inner loops reach the C kernels' speed without `unsafe` escapes.

## 7. Addendum: a Swift VT model (T0.4, first result) [probed]

Headless Swift model on six vtebench-equivalent streams (1 MiB, 120×40, 64 KiB chunks, `swiftc -O`, best of 15; `probes/vtmodel.swift`), ms per MiB, lower is better:

| Stream | scalar scan | `any(mask)` SIMD | `max()` SIMD | hybrid |
|---|---|---|---|---|
| scrolling (`y\n`, 2-byte runs) | 8.65 | 37.09 | 9.29 | 9.20 |
| scrolling_fullscreen (120-byte runs) | 1.04 | 4.82 | **0.72** | 0.77 |
| scrolling_top_region | 9.81 | 40.86 | 9.84 | 9.87 |
| dense_cells (SGR per cell) | 6.91 | 8.49 | 6.97 | 6.58 |
| medium_cells (vim session) | 4.65 | 8.29 | 4.70 | 4.70 |
| unicode | 1.76 | 1.85 | 1.98 | 1.97 |

All four variants end in the same screen (checksum) and hand tests pass (wrap, scroll, SGR); that is **not** a conformance claim.

- **A SIMD formulation can cost 4×:** Swift's `any((v .< 0x20) .| (v .>= 0x7F))` compiles badly; the unsigned trick `(v &- 0x20).max() >= 0x5F` removes the penalty and gives 1.4× on long runs. Rule for Sunset: every SIMD idiom in Swift is measured before use; the C kernels in Aemi remain the safer route.
- **Scanning does not matter much; the state machine and cell writes dominate, and the whole model costs 1–10 ms per MiB.** At 17 ns per `y\n` pair (print, LF, row-map rotate, clear one 960-byte row) the scrolling stream costs 8.7 ms per MiB, against 46 ms (Ghostty) and 76 ms (Alacritty)
  for the same workload end to end in the first noisy competitor pass. These are **not comparable** (the terminals include PTY, rendering, locking and more features; the model does less), but it says the parse and cell core is not where Sunset would lose on these workloads, and gives the budget: Sunset's real core may spend 2–3× the model and still beat the best terminal here. To be re-measured with scrollback, paged styles, graphemes and the safe `Span` version.
- Row indirection (logical → physical row ids, rotated on scroll) makes scrolling regions as cheap as full-screen scrolling (9.8 vs 8.7 ms), the trick kitty (`line_map`) and Ghostty (offset rows) use.

### 7b. Correction and second round (T0.1, T0.4b) [probed]

- **Correction:** the stream behind the table above lacked `\r` (no ONLCR), so the scrolling rows measured a staircase workload. Regenerated with `\r\n`; the corrected single quiet-window run of `probes/vtmodel2.swift` (column C8) is: scrolling 5.2, fullscreen 0.62, top region 5.2, dense_cells 5.7, medium 4.3, unicode 1.5 ms/MiB, with a 10,000-row hot scrollback ring adding ~1.6 ms/MiB on scrolling and ~0.1 on log.
- **Cell width** (same state machine, ms per MiB, scrollback off; quiet window): scrolling 5.2 / 7.6 / 19.9 for 8 / 16 / 32-byte cells; dense_cells (SGR per cell) 5.7 / 5.7 / **4.6** (32-byte cells carry colours inline and skip the style table); other streams tie. Under load the same ratios held (scrolling 10.4 / 15.3 / 35.8, dense 9.0 / 7.9 / 7.5).
  So: the 8-byte hot cell is 1.5× the 16-byte one and 3.8× the 32-byte one on scrolling (the cost is row clear and stores, proportional to bytes), and the one place a table loses is the SGR-dense stream, by about 20%, because every SGR pays a lookup. I tried an open-addressing table with a last-key shortcut; under load it did **not** visibly close that gap. Quiet rerun owed.
- **Scrollback ring with zero-copy slot reuse** (retired rows stay where they are; rows are renamed, not copied; Alacritty's ring and Ghostty's offset rows are the same idea): +1.6 ms/MiB on the 2-byte-line scrolling stream, ~0 on realistic logs.
- **Cold structural encoding of evicted rows, live in the parse loop (single thread, allocating, deliberately naive):** on an 8.5 MiB coloured log built from real text, **57 bytes per row** against 960 for a hot row of 120 cells (5.9%, 0.47 B/cell, matching the 0.45 B/cell of the earlier synthetic probe), 7 B/row on near-empty rows; encode 0.1–0.45 µs per row (+7.5 ms/MiB on the log stream if done on the parse thread), a cold walk of 138,233 rows in 5 ms (**36 ns per row**).
  Evicted rows are immutable, so encoding belongs on a worker thread, costing the parser nothing; the numbers above are an upper bound for it. Encoders for 8, 16 and 32-byte cells produce identical output on both streams (checked).
- Still not measured: the real transcript corpus, truecolor-heavy output, reflow, LZ4 after structural (kernel not written), page-local style sets with splits.

### 7c. Real-text cold history (T0.2) [probed, deterministic]

On 16 and 64 MiB of rendered ask-session text (ADR-0013 evidence): LZ4 of raw 8-byte-cell pages 100.6 B/row; structural 59.8; **structural then LZ4: 27.3 (3.7× smaller than LZ4 of raw)**. So the LZ4 kernel's job in Sunset is compressing small structural segments (cold history, snapshots), not raw cell pages, and the structural encoder/decoder is the first codec to write (roadmap 0015, item "structural row encoder").
