# How Alacritty and Ghostty move bytes to pixels, and which ARM kernels would help Sunset

Written 2026-11-06 at the owner's request ("investigate the architecture and design of alacritty and ghostty and study arm/neon/assembly kernels that would help us"). Sources are the trees in `/tmp/ref/alacritty` (the 0.18-dev build used in the benchmarks) and `/tmp/ref/ghostty` (a checkout whose exact version I did not record; the installed app used in the benchmarks is 1.4.0). Labels: **[read]** the source, **[probed]** I ran it today on this Apple M3 (`probes/fill-blend.c`, `clang -O2`), **[measured]** from Sunset's own benchmarks this session, **[unverified]** a claim I did not test.

## 1. Ghostty

**Input path [read], `src/termio/Exec.zig` (ReadThread).** The comment there is the most useful paragraph I found: *"on macOS the kernel tty output queue caps every read on the master at 1 KB no matter how large the read buffer is"*, so a producer such as `cat` stalls whenever the reader is parsing instead of draining. Their fix is a two-stage pipeline of two threads: **io-gather** does `read()`/`poll()` into one of **4 rotating 64 KiB buffers**; **io-reader** takes each filled buffer, locks the terminal, parses, schedules a render. Details that matter: a batch is delivered on the first EAGAIN unless the stream is *saturated* (a full 1 KiB read means the writer filled the queue); on a saturated stream an EAGAIN is retried up to **16 times with an immediate read** (a refill gap is a few microseconds, a poll sleep and wake-up costs more), then a **1 ms poll**, with a **3 ms budget** per batch; an idle self-pipe lets the parser stop the bridging the moment it runs out of work, so interactive latency is unchanged; 4 buffers was "measured on an M4 Max: fewer is slower, more is no better". My own measurement of the same kernel behaviour: 4 MB arrived as 3154 reads, about 1.3 KiB each **[measured]**.

**Parser [read], `src/terminal/stream.zig`, `src/simd/vt.cpp`.** In the ground state the stream calls `utf8DecodeUntilControlSeq`: a SIMD scan (Highway, so NEON on Apple silicon) for **ESC only**, then **simdutf** converts the span UTF-8 → UTF-32 (invalid sequences become U+FFFD by the maximal-subpart rule). ASCII is not even converted: it stays in the input. The decoded span is cut into *runs* of printable scalars by a vector compare (`v < 0x20`, or one AND-test `(cp & ~0x9F) == 0` for C0 and C1 together) and each run goes to the terminal as one `print_slice`, so the grid is written per run, not per character. Other C0 controls inside a run are executed between runs.

**Terminal data [read], `src/terminal/page.zig`, `Terminal.zig`.** A cell is a packed `u64` (tag, 21-bit codepoint or colour, 16-bit style id, wide flags), like ours (8 bytes). Rows live in *pages* (linked, fixed-size, offset-addressed memory with ref-counted styles and a bitmap allocator). The decisive design point is scrolling: `Terminal.index()` at the bottom of a full-width region calls `cursorScrollAbove()`, which **grows the page list by one row**; the active screen is simply the last N rows of the list and the row that left the top is already history, in place. Nothing is copied to a scrollback and no row order is rotated; the new row is cleared. Scrollback pruning drops whole pages.

**Render state [read], `src/terminal/render.zig`.** The comment says it plainly: the renderer used to `clone` the visible screen each frame (this is what Sunset's snapshot does) and *"the clone time was repeatedly a bottleneck blocking IO"*. Replacement: a persistent `RenderState` updated on each frame in two phases (under the terminal lock only the dirty rows are read; the rest of the update runs outside the lock), with per-row dirty flags driving what the renderer rebuilds.

**Renderer [read], `src/renderer/`.** Metal on macOS (OpenGL elsewhere): an instanced draw of one 32-byte `CellText` per glyph (atlas position and size, bearings, grid position, colour, atlas kind), a per-cell background colour buffer sampled in the fragment shader, a glyph atlas (grayscale and colour), rows rebuilt only when dirty (`rebuildCells`, `state.dirty == .full` forces everything), presented with a `CAMetalLayer`/IOSurface layer and a display link.

## 2. Alacritty

**Input path [read], `alacritty_terminal/src/event_loop.rs`.** One PTY thread (mio poll): a **1 MiB** read buffer; it reads until WouldBlock, and parses while holding the terminal lock obtained with `try_lock_unfair`; if the lock is taken it keeps reading (into the big buffer) rather than waiting, and it forces the lock only when 1 MiB is unprocessed; it never holds the lock for more than **64 KiB** (`MAX_LOCKED_READ`) so the renderer is not starved. This is the serial design Ghostty's comment says stalls producers; Alacritty still posted the best throughput in the tables of 2026-11-05 and 2026-11-06 together with Ghostty (vtebench: scrolling 20 ms against Ghostty's 17), so the serial design is not what makes a terminal slow, our *cost per read* was **[measured]**.

**Grid [read], `grid/storage.rs`, `grid/mod.rs`.** Rows (`Vec<Cell>`, 24-byte cells) live in a **ring buffer** that holds the screen *and* the scrollback; `rotate` is `zero = (zero + count) % len`, a modular addition. `scroll_up` of the full screen rotates the ring and resets the one row that came round (`increase_scroll_limit` grows the history in place); only scrolling regions that do not start at row 0 swap rows. As in Ghostty, a scroll copies nothing to a history.

**Parser.** The `vte` crate: a table-driven byte state machine, no SIMD; UTF-8 decoded in the state machine. Parse speed is not Alacritty's advantage; its advantages are the in-place scroll, the lock discipline, and the GPU.

**Damage and drawing [read], `display/damage.rs`, `renderer/text/glsl3.rs`.** Per-line damage bounds; frame damage rectangles passed to `swap_buffers_with_damage` where the platform allows; text drawn as instanced quads (`InstanceData`: cell, glyph offset and size, UV, colours) in batches of 65 536 from a glyph atlas.

## 3. Where Sunset differs, with its own numbers

| Aspect | Alacritty / Ghostty | Sunset today | Evidence |
|---|---|---|---|
| Pty read to parse | Ghostty: 2 threads, 4×64 KiB ring, spin-bridge. Alacritty: 1 thread, big reads, lock fairness | One thread reads and parses in place (since `aec142e`): the producer stalls while we parse | the Ghostty comment; ours **[measured]** 2.5x fewer instructions than the previous async version, scrolling benchmarks did not move |
| Scroll a line | in place (ring / grow a row): O(1), no copy | rotate the 40-entry row map, **copy the line into the history** (960 B), blank the row | `terminal/line_feeds` **[measured]**: 634 M instr per MiB, 402 M with history off |
| Frame snapshot | Ghostty replaced a per-frame clone by dirty-row updates | `takeSnapshot` copies the screen; the grid is shared until the next write, which then copies it (38 KB) and the newest history chunk | **[read]** code; cost not isolated |
| Draw | GPU instanced quads; only dirty rows | CPU: a row strip fill plus a per-glyph, per-pixel scalar blend; the compositor does the colour conversion | full frame 29 M instr, 8 ms **[measured]** |
| ASCII | SIMD scan, runs | scalar byte loop to the end of the run, then a scalar cell loop | 38 M instr per MiB **[measured]**: 36 instructions a byte |
| UTF-8 | simdutf, bulk | scalar whole-sequence decode (since `b7263cf`) | 137 M instr per MiB **[measured]** |

## 4. Probes run today [probed]

`probes/fill-blend.c`, `clang -O2`, Apple M3, best of 7, one terminal row's worth of data.

| Loop | Scalar | Hand NEON | libc | Reading |
|---|---|---|---|---|
| fill a row strip of 2040x34 RGBA pixels (277 KB) | 4.70 us, 59 GB/s | 5.52 us | `memset_pattern4` 4.86 us | **no gain**: the compiler already vectorises the loop and it is store-bound |
| blank 120 cells (960 B) | 19.4 ns | 19.4 ns | `memset_pattern8` 28.6 ns | **no gain** |
| blend 8-bit glyph coverage over RGBA (40 320 pixels, 40 % non-zero), exact `(c*a + d*(255-a) + 127)/255` | 183.9 us, 4.56 ns/px | **34.4 us, 0.85 ns/px** | – | **5.3x**, 0 of 40 320 pixels differ from the scalar formula |

So: hand-written fill and memset kernels are a waste (consistent with Aemi's rule "measure at the real flags, scalar reference first"); the glyph blend is a real kernel, exact, and it is the loop that dominates a CPU frame (800 000 blended pixels per full 120x40 frame at 4.6 ns would be 3.7 ms of the 8 ms measured; the rest is the strip fills and cell logic **[unverified: not profiled by function]**). Earlier probes in `kernels-study.md` still stand: bulk control-byte positions 5-10 GB/s (scanning is not the bottleneck), ASCII to 8-byte cells 1.7x, first differing cell 2.3-2.8x.

No assembly: nothing here needs it; intrinsics compile to the same instructions and stay portable and testable against the scalar reference (Aemi's discipline, `kernels-study.md` section 4).

## 5. Recommendations, ranked by expected effect on what the owner sees

Each needs its own red-first test or benchmark and an interleaved A/B on instructions before any claim.

1. **Two-stage input pipeline à la Ghostty** (gather thread + parse thread, 4×64 KiB ring, spin-bridge, bounded budget, idle self-pipe). Their own measurements say the drain rate nearly doubles on a saturated stream; our current serial reader has exactly the stall they describe. Swift: two `DedicatedThread`s, a `Mutex` for the ring metadata and a condition (Foundation's `NSCondition`; no Dispatch). Keeps interactive latency by delivering on the first EAGAIN of a non-saturated stream. *Expected: the largest wall-clock gain on the scrolling and dense benchmarks; unverified until built.*
2. **Scroll without copying into a history** (the ring / grow-a-row design). 230 M of the 634 M instructions per MiB of `line_feeds`, and the memory traffic that goes with it (8x the input bytes written per line). Risk: our chunked, snapshot-shared `Scrollback`, reflow, prompt marks and the stable-line numbering were built around a separate history; a ring of rows that holds both has to keep sharing cheap for snapshots. Needs a design note before code.
3. **Render state instead of a whole-screen snapshot** (Ghostty's source says it kept the clone through the 1.2.x series): the renderer keeps a persistent copy and the session hands over only the dirty rows. Removes the per-frame grid copy and its CoW copy on the next write. Not isolated yet; measure first with the 5 s sample and `terminal/flood with a snapshot per read`.
4. **NEON glyph blend in the CPU renderer** (5.3x on the blend loop, exact, probe above), as an Aemi-style kernel with a scalar reference and differential tests at every width and alignment, behind the renderer's seam, with the pure-Swift path kept as the oracle. The renderer is the product's reference, so exactness is a gate: the probe already matches the exact formula bit for bit.
5. **GPU renderer (Metal)**, the thing both competitors do: instanced glyph quads, a per-cell background buffer, dirty-row rebuilds. Already planned (t53, `auto|gpu|cpu`). Not the cause of the benchmark gap by itself (a render-off run changed one vtebench case by about 10 %), but the way to make floods and full-screen changes cost little CPU and energy.
6. **ASCII run kernel** (classify 16 bytes, widen into cells): ~1.7x on its own loop in the earlier probe; parse is 1.7 ms of a 50 ms benchmark, so low priority. **UTF-8 bulk decode** (simdutf-style, NEON): Aemi has validation only; a gain only for non-ASCII-heavy output; low priority after the scalar inline path.
7. **Not worth doing:** hand NEON/assembly for fills, memsets, row blanking (probe: no gain), more scanning kernels (not the bottleneck).

## 6. Not verified

I did not read Ghostty's page allocator, scrollback pruning or kitty-graphics code, nor Alacritty's glyph cache, beyond what is cited; I did not run Ghostty's own benchmarks (`src/benchmark`); numbers quoted from the Ghostty comments are theirs (M4 Max). The 5.3x is a C probe at `-O2` on random coverage; the Swift blend in the app has bounds checks and an array-copy check per pixel and may be slower than the C scalar, so the gain in the app may be larger, and the share of a frame spent in the blend is an estimate. Recommendation 1's gain on Sunset is a prediction from Ghostty's report, not a measurement.
