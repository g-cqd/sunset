# How kitty, Ghostty, WezTerm and Alacritty get their performance — and where Sunset can beat them

Read 2026-11-05 from shallow clones (kitty `bdbf9f5`, Ghostty, WezTerm, Alacritty and `vte`, current `main` of each that day) in `/tmp/ref`. **I read source comments, struct definitions and a few control
flows; I ran none of these terminals** (only kitty is installed here) **and measured nothing.** Every "faster/smaller" below is a hypothesis for a probe, never a result. File names are given so each
claim can be re-read. Vendor figures are the vendor's.

## 1. What each one does (read)

### Ghostty (Zig) — the most sophisticated memory design
| Mechanism | Evidence |
|---|---|
| **8-byte cell** (`packed struct(u64)`): content tag, 21-bit codepoint *or* an inline palette/RGB background colour (a background-only cell needs no style), 16-bit style id, wide/protected/hyperlink/semantic bits | `src/terminal/page.zig` `Cell` |
| **Styles are per page and reference-counted** (`std_capacity`: 215×215 cells, 128 styles, 8 KiB of grapheme bytes), so a page's style table is tiny and bounded; style 0 is the default and needs no lookup | `page.zig`, `style.zig`, `ref_counted_set.zig` |
| **Pages are `mmap`'d, page-aligned, zero-filled, and use offsets, not pointers**, so a page can be copied, compressed and restored with `memcpy` semantics; allocation fast path is the OS | `page.zig` header comments |
| **Row flags that may be false positives but never false negatives** (`styled`, `grapheme`, `hyperlink`, `semantic_prompt`, `kitty_virtual_placeholder`): erase/insert/delete take a fast path when the flag is clear ("around 4×" faster, their comment) | `page.zig` `Row` |
| **Bitmap allocators** for grapheme clusters (chunks of 4 codepoints) and for shared strings (32-byte chunks) inside the page: no malloc per cluster | `bitmap_allocator.zig`, `page.zig` |
| **Cold scrollback pages are LZ4-compressed and their physical memory is released** (`MADV_FREE_REUSABLE`/`MADV_DONTNEED`) while the virtual range is kept so restore needs no allocation; policy lives in `PageList`; a resize decompresses | `terminal/compress/Page.zig`, `PageList.zig` (`Storage = resident | compressed`) |
| **Page pool preheated with 4 untouched pages** (an untouched page costs no physical memory) | `PageList.zig` `page_preheat` |
| **SIMD UTF-8 decode-until-ESC** (Highway + simdutf, with exact maximal-subpart U+FFFD replacement) and a **differential test against the scalar path**; parse table generated at compile time | `src/simd/vt.cpp`, `vt.zig`, `terminal/parse_table.zig` |
| **Three threads**: IO reader/parser, a writer thread (to keep the parse path free), and a renderer thread; the renderer **snapshots the viewport under a mutex held for microseconds**, builds GPU cells outside the lock | `termio/Thread.zig`, `renderer/State.zig`, `renderer/generic.zig` |
| **Lock starvation fix**: Zig/pthread/`os_unfair_lock` are unfair, a hot IO loop beats a sleeping renderer, so the renderer announces *demand* and the IO loop hands the mutex off (1 ms bound) | `renderer/State.zig` `lockDemand`/`yieldToDemand` |
| **Per-row dirty flags and a three-state terminal dirty (`false`/`partial`/`full`)**; rows rebuilt only when dirty; swap chain of frames; display-link driven | `page.zig` `Row.dirty`, `renderer/generic.zig` |
| GPU data: per glyph a **32-byte `CellText` instance** (atlas position/size, bearings, grid position, colour, grayscale-or-colour atlas flag); backgrounds are **4 bytes per cell** in a separate buffer | `renderer/metal/shaders.zig` |
| Synchronized-output timeout resets the mode so a bad program cannot freeze the terminal | `termio/Thread.zig` |

### kitty (C, Python on top)
| Mechanism | Evidence |
|---|---|
| Cells split in `CPUCell` (12 B: codepoint-or-index, hyperlink id, multicell bits) and `GPUCell` (20 B: fg, bg, decoration colour, **sprite index**, attrs): **the GPU array is the cell array**; colours are inline (no style table) | `kitty/line.h` |
| **Input rate limiting by design**: the I/O thread wakes the main loop at most once per `input_delay` (3 ms default per docs) because "wakeup is an expensive operation"; `repaint_delay` throttles drawing; a turn that parsed bytes paints again | `child-monitor.c` (~l. 561–570, 996, 1221–1254, 2084–2119) |
| History in **mmap'd segments** of CPU/GPU cell arrays plus a **separate `PagerHistoryBuf` ring of text** (compact, for the pager) | `history.c`, `history.h` |
| SIMD scanning for plain-text runs; a **gamma LUT** for text contrast uploaded to the GPU | `simd-string.c`, `shaders.c` `upload_gamma_lut` |
| Glyphs rasterised once into a sprite atlas; images in a disk cache | `docs/performance.rst`, `disk-cache.c` |
| Embeds Python (a large resident baseline; not measured) | build tree |

### Alacritty (Rust) — the minimal design
| Mechanism | Evidence |
|---|---|
| **Ring-buffer grid** whose scroll is a modular add of a `zero` offset (no row moves) | `alacritty_terminal/src/grid/storage.rs` |
| `Cell` ≤ **24 bytes** (`char`, fg, bg, flags, `Option<Arc<CellExtra>>` for zero-width, underline colour, hyperlink), asserted | `term/cell.rs` |
| **1 MiB read buffer; `try_lock_unfair` and keep reading while the lock is busy; force the lock only at 1 MiB unprocessed; release after 65,535 processed bytes** | `event_loop.rs` (`READ_BUFFER_SIZE`, `MAX_LOCKED_READ`) |
| **Fair mutex** (an extra "next" lock so a waiting thread wins over a re-locker) | `sync.rs` |
| **Damage tracking per line (left/right bounds) + full flag**; used for partial presenting | `term/mod.rs` `TermDamageState` |
| **vte** parser: table-driven state machine, tiny fixed buffers (2 intermediates, 16 OSC params, 1 KiB OSC), `Perform` callbacks with no intermediate allocation | `vte/src/lib.rs` |
| Synchronized updates buffered up to **2 MiB / 150 ms** then forced | `vte/src/ansi.rs` |
| OpenGL **instanced** text, 65,536 instances per batch, atlas 1024², `BufferSubData`; ligatures/images/tabs absent by design | `alacritty/src/renderer/text/glsl3.rs` |

### WezTerm (Rust) — feature-rich, slower by construction (hypothesis)
| Mechanism | Evidence |
|---|---|
| Parser produces **`Action` values appended to a `Vec`**, shipped to the mux; an allocation-heavy pipeline | `mux/src/lib.rs` `parse_buffered_data` |
| **Coalescing delay** to gather "a full frame" from unoptimised TUIs, bypassed while in synchronized output or past the buffer size | same |
| `Line` stores cells as a **`ClusteredLine`** (one string + attribute clusters + a wide-char bitset) instead of one cell per column: a compact scrollback form; each `Line` carries a **sequence number** used for change detection | `wezterm-surface/src/line/{line,clusterline,storage}.rs` |
| 1 MiB socket/read buffers; histogram metrics built in | `mux/src/lib.rs` |

## 2. What this teaches, as design constraints for Sunset

1. **The cell is the memory budget.** Ghostty's 8 B (with per-page style ids and background-only cells inline) is the best hot-path density seen; kitty's 32 B and Alacritty's ≤24 B are larger.
   *Constraint:* hot cells ≤ 8 B. TerminalKit's `PackedCell` is 16 B with a process-wide table (ADR-0021 there), so it cannot be reused unchanged (ADR-0005 here; refined in ADR-0012).
2. **Cold history should cost almost nothing, and nobody has gone all the way.** Ghostty compresses raw pages with LZ4 and decommits them; WezTerm stores clustered lines; kitty keeps a text ring.
   *Hypothesis:* a **structural** encoding (UTF-8 text per row + style runs + wrap/prompt flags, deduplicated styles) beats LZ4 over raw 8-byte cells on real transcripts, and decodes lazily per row for
   search and reflow. *Probe:* compare, on the 139-transcript corpus used for ADR-0021 (225 MB, local), bytes per cell and decode µs per row for raw, LZ4-of-page and structural (ADR-0013).
3. **Never let the reader and the renderer fight over one lock.** Every terminal had to engineer around it (Alacritty fair mutex + `try_lock` batching; Ghostty demand handoff). *Hypothesis:* a design with **no lock at all**,
   where the renderer raises an atomic "frame wanted" flag and the reader, between parse chunks, publishes the dirty rows into a triple buffer (cost O(dirty cells) on the reader, no waiting anywhere), gives
   higher throughput under sustained output *and* lower frame-time p99 than the lock variants. *Probe:* four variants in one harness (unfair mutex, fair mutex, Ghostty-style demand, snapshot-on-request), heavy output, measuring
   reader MB/s and renderer stall p99 (ADR-0014).
4. **Parse straight into cells, in runs.** No `Action` objects (WezTerm), no per-cell callback. A printable-ASCII/UTF-8 run is found with a vector scan (Ghostty `vt.cpp`, kitty `simd-string.c`) and written as one run with one style and one
   width decision (ASCII needs no width lookup). Aemi already has byte kernels (`AemiKernels` UTF-8/Find/ByteSet; the C target `CAemiKernels`) — whether they are fast enough here is a probe. Keep Ghostty's best idea: a **differential test of the
   SIMD path against the scalar path** on random mixed input.
5. **False-positive row flags** (Ghostty) are cheap and give 4× on erase paths by their own comment; adopt and re-measure.
6. **Wakeups are the cost nobody advertises.** kitty rate-limits wakeups; WezTerm coalesces with a delay; both trade latency for CPU. *Hypothesis:* schedule against the **display's vsync deadline**: wake the renderer once per frame, start the frame as late
   as the measured p99 frame cost allows ("late latch") so the newest bytes make it in, and sleep entirely when nothing changed (TerminalKit roadmap 0025's idle = 0 wakeups). Beats fixed delays on both latency and power if it works.
   *Probe:* a software proxy (key → presented-time via the display link's presentation feedback), because key-to-photon needs hardware we do not have (said plainly in roadmap 0009).
7. **Make the GPU read the cells.** All three GPU terminals rebuild instance data on the CPU (Ghostty 32 B per glyph; Alacritty per-frame batches), except kitty, whose `GPUCell` array is uploaded as is. On Apple silicon (unified memory) the
   **screen's own page memory can be the Metal buffer** (page-aligned `mmap`, `makeBuffer(bytesNoCopy:)`): zero per-frame CPU rebuild and zero upload; glyph lookup in the shader through a codepoint → atlas-slot table, with a side buffer only for
   rows that need shaping (ligatures, emoji sequences). *Risk:* consistency between writer and GPU read (triple-buffer the small active screen; cold pages are immutable), and the shaping side channel. *Probe first:* a Metal micro-benchmark, 120×40 and
   300×80, CPU-rebuilt instances vs direct cell reads, frame CPU time and GPU time (ADR-0015). This is the biggest bet in the plan; it is not assumed.
8. **Partial redraw saves GPU and power, not only CPU.** Alacritty tracks damage per line for it; Ghostty rebuilds dirty rows. A Metal drawable still presents whole, but keeping the previous frame and drawing only dirty rows (scissored,
   `loadAction = .load`) may cut GPU time; unmeasured, so a probe with `powermetrics`-class numbers (needs root; may not be available).
9. **Text quality is part of the performance story.** kitty has a gamma LUT for text contrast; Ghostty has a minimum-contrast option per cell (`no_min_contrast`); both are cheap GPU-side. Fits ADR-0009 (colour pipeline).
10. **Bounded everything and a timeout on synchronized output** (Alacritty 150 ms / 2 MiB, Ghostty a timer): a misbehaving program must not freeze the terminal (white paper §9).
11. **Footprint at idle** is a design target no competitor states: no embedded interpreter (kitty), lazy GPU/atlas/fallback-font creation, preheated-but-untouched pages (Ghostty), shared glyph atlas across tabs/windows, a Swift binary that links only what it uses
    (white paper). *Probe:* resident memory at launch, after 1 and 10 tabs, and after 1 M lines of scrollback, same workload, for each competitor and for Sunset, by `footprint`/`vmmap` (physical footprint, not RSS alone).

## 3. What "better on all aspects" has to mean (measurable gates)

Compared on the same machine, same workloads, release builds of each, by a harness that runs the other terminals as processes (ADR-0004), reporting percentiles with units:

| Axis | Metric | Workloads |
|---|---|---|
| Speed (throughput) | MB/s parsed to screen model, and to screen with rendering on | vtebench workloads (Alacritty's tool; SwiftTerm ported them), ASCII, Unicode/emoji, SGR-dense, scrolling, images |
| Speed (latency) | key → handled, key → screen model, key → presented timestamp (proxy), frame time p50/p99 under load | typing during `yes`, during a build log, idle |
| Efficiency | idle wakeups/s, CPU% for a fixed scrolling task, energy proxy | idle with cursor blink off/on, `less` scrolling, streaming log |
| Memory | physical footprint at launch, after N tabs, after 1 M scrollback lines (structured vs LZ4 vs raw) | transcript corpus; synthetic truecolor |
| Startup | time to first frame, time to interactive shell | cold and warm |
| Robustness | no crash, bounded memory and time on hostile input | fuzz corpus; sync-output abuse; image bombs |

Sunset is "better" on an axis only when it beats the best of the four on that axis, p50 **and** p99, repeated, with the harness checked in. Where it does not, the plan says so and the entry stays open.

## 4. Not yet known (open questions)

- Ghostty's actual compression ratio and policy thresholds (read the header comments, not `PageList` policy code); Ghostty's renderer's real CPU/GPU cost per frame.
- Whether Alacritty/kitty/Ghostty/WezTerm numbers on this machine match their published ones (nothing run; only kitty is installed). Needs `brew install --cask ghostty wezterm alacritty` (oracles, ADR-0004) — **not done, owner to approve**.
- Whether Swift can match C++/Zig SIMD scanning without `unsafe` escapes beyond what StrictMemorySafety tolerates (white paper: every `unsafe` justified); `SIMD16<UInt8>` and Aemi's C kernels are the options.
- Swift's actual cost of `Span`/`RawSpan` bounds checks in the parser's inner loop (probe).
- Whether Metal `bytesNoCopy` buffers over `mmap` pages behave as needed on all supported Macs and under memory pressure (`MADV_FREE_REUSABLE` interplay, and the GPU mapping of decommitted pages).

## 5. Update, measured on this machine (2026-11-05; see roadmap 0014 and bench/)

First competitor numbers now exist: vtebench (noisy, load average 7–17; wall times, Ghostty fastest on all rows) and idle/footprint (deterministic counters, one sample each). Footprint after 1 M lines with 100,000 lines of scrollback: WezTerm 81 MB, Ghostty 136 MB, Alacritty 412 MB, kitty 470 MB; idle wakeups per second: Alacritty 0.3, kitty 0.5–4.4, WezTerm 5.7, Ghostty 15–16. Sunset's targets are the best of each column (roadmap 0014). Sunset's own cold-history measurement (ADR-0013: 27 B per row structural + LZ4, 100,000 rows ≈ 2.7 MB) says the scrollback is not where its footprint will go; the application baseline (Swift runtime, Metal, atlas, fonts) is.
