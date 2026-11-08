# Renderer: what the first GPU version really costs, and the plan (2026-11-08)

Owner: "your implementation is suboptimal… challenge your own claims, study all paths, come back with a better plan".

**How measured.** `docs/research/probes/renderer-stages.swift` (a test-target probe, moved out of the suite; copy it into `Tests/SunsetRenderMetalTests` to run): Menlo at 28 px, retina-sized surfaces, 200 frames per case, release, the same screens through the CPU renderer and through `record` + `MetalCompositor.apply`; GPU execution from the command buffer's `gpuStartTime`/`gpuEndTime`, CPU cost of `apply` from `CLOCK_THREAD_CPUTIME_ID`. One machine (Apple silicon, load 2-10), one run per row: read differences under 15 % as noise. Plus whole-app `proc_pid_rusage` and `sample` runs.

## 1. Measurements (µs per frame, mean of 200)

| 120×40 (2048×1328 px) | ops | CPU renderer | GPU path: record (CPU) | apply wall | of which GPU exec | apply thread CPU |
|---|---:|---:|---:|---:|---:|---:|
| scroll 1 line | 4 362 | 1 811 | 368 | 1 128 | 517 | 135 |
| scroll 5 lines | 4 368 | 1 817 | 372 | 1 091 | 482 | 136 |
| full redraw (vim-like) | 4 480 | 1 823 | 385 | 1 119 | 504 | 139 |
| type 1 char | 75 | 36 | 9 | 279 | 32 | 10 |
| cursor blink | 1 | 9 | 4 | 273 | 32 | 8 |

| 300×80 (5108×2648 px) | ops | CPU renderer | record | apply wall | GPU exec | apply CPU |
|---|---:|---:|---:|---:|---:|---:|
| scroll 1 line | 23 053 | 9 945 | 1 819 | 4 256 | 3 118 | 589 |
| full redraw | 23 360 | 9 989 | 1 824 | 4 285 | 3 214 | 534 |
| type 1 char | 102 | 55 | 15 | 349 | 50 | 11 |
| cursor blink | 1 | 23 | 9 | 265 | 52 | 8 |

Also: parsing a frame's bytes is 3-112 µs, and **holding a snapshot while parsing costs nothing measurable** (copy-on-write of the grid does not show). Whole app idle after the cursor stops blinking: **0 wakeups/s, 0-0.02 M instructions/s, both backends**; while blinking: 20-23 M instructions/s, 26 wakeups/s (the `sample` shows nothing of ours above noise). A 1 M-line flood: 13.3 G instructions CPU backend, 12.4-12.8 G GPU (parsing dominates).

## 2. Claims of mine that were wrong or unproven

1. *"The GPU path is not faster at a normal window size"* (earlier diary). **Wrong as stated.** That compared wall time, and half of the GPU's wall is the thread asleep in `waitUntilCompleted`. In CPU time a full 120×40 frame is **1 811 µs on the CPU renderer against 503 µs on the GPU path (3.6×)**, 300×80 **9 945 against 2 408 (4.1×)**. Small frames: 36 against 19 (type), 9 against 12 (blink): equal.
2. *"Idle costs 150 M instructions/s"* (renderer A/B). **Wrong**: sampled while the cursor still blinked. Idle is zero.
3. *"Scrolling redraws the whole screen"*: true, but the full-redraw row shows the same cost, so it only matters for the scroll workloads, not for floods or full-screen programs. And the core **already knows** a scroll happened (it rotates `Grid.rowMap`, `Screen+Scroll.swift:53`) and then throws that away by marking every row dirty.
4. *"Integer division in the shader is the GPU cost"* (implicit in suggesting it). **Tested and false**: replacing `/255` with the exact shift form changed nothing beyond noise (497-680 against 482-517 µs).
5. *"Snapshots cost a grid copy"* (a worry from earlier work). **Not measurable** (see above).
6. Not wrong but missing from my last answer: **`waitUntilCompleted` blocks a thread of Swift's cooperative pool** (`MetalSurfaceRenderer` is an actor), against our own concurrency rule; with several windows a few hundred µs per frame each of a pool thread is lost.
7. *"GPU memory is +10 MB"*: right number, wrong cause unstated: it is the **canvas texture** (one frame-sized buffer). Each window holds **four frame-sized buffers on either backend** (CPU: `Surface` + 3 IOSurfaces; GPU: canvas + 3 IOSurfaces): 4 × 10.9 MB at 120×40 retina, 4 × 54 MB at 300×80. That is real memory for n11.

## 3. Where the time goes (the paths)

- **Per frame, any backend**: `record` / the CPU renderer's cell loop is about **85 ns per drawn cell** (368 µs for 4 362 ops). Read in `CPURenderer+Rows/Runs/Glyphs`: per cell a row-map lookup, a style table lookup, two palette resolves, a `GlyphKey` hash-dictionary lookup (five fields, SipHash), the cursor/selection checks, decorations, and, recording, an enum append that retains a class (`GlyphBitmap`). Only **25 distinct bitmaps** were used in 4 300 glyph ops: the dictionary is doing the work of a small array.
- **CPU backend**: the remaining ~1 450 µs of a full frame is pixel work (row fills and coverage blends), then the app copies the changed rows into an IOSurface (not timed separately: to measure).
- **GPU backend**: ~135 µs CPU to build instances (a second pass over the ops), copy them, encode; GPU **0.12 µs per instance** (517 µs for 4 362) which is slow for 1.7 M fragments: not the divisions (item 4); unexplained, needs a GPU capture (candidates: programmable blending with framebuffer fetch over overlapping primitives, full-width row fills under every glyph, quad size). Then a blit of the changed rows (the whole frame when scrolling) from the canvas into the IOSurface. Then a ~250 µs **fixed wall cost** per submitted frame, nearly all waiting (thread CPU 8-10 µs on a 1-op frame).

## 4. The plan, in order (each: expected effect, how it is proven, risk)

1. **Stop blocking the pool; pipeline frames.** `addCompletedHandler` into a continuation (or the renderer on a `DedicatedThread` executor, which SunsetHost has), a ring of 3 instance buffers, at most 2 frames in flight; atlas uploads only into regions no in-flight frame reads (the atlas is append-only until `clear`, so only `clear` must wait). *Effect*: the ~250 µs wait leaves the frame path (latency per frame stays, CPU unchanged); no pool starvation. *Proof*: the probe's wall per frame for a 1-op frame, and a test with 8 renderers on the pool. *Risk*: low.
2. **Scroll by moving pixels, not by redrawing.** The core records, per snapshot, "the full-width scroll region moved up by *k* rows" (it already rotates the row map) and marks only the new rows dirty; any other change to a moved row marks that row too, so correctness does not depend on the shift. Renderers: GPU blits the previous surface into the next one offset by *k* cell heights, then draws the new rows (one blit that is also the missed-rows copy); CPU does the same on the IOSurface. Falls back to a full redraw for margins, partial regions, reflow. *Effect, estimated*: the scroll-1-line frame from ~4 300 ops to ~110 (one row), i.e. most of 1.8 ms (CPU) or 0.5 ms CPU + 0.5 ms GPU at 120×40, ×5 at 300×80, plus a frame-sized copy. **Not for floods** (each frame there is many lines; still a gain when *k* < rows) **nor for full-screen programs**. *Proof*: a core test (shift recorded, rows dirty only where new), the pixel-differential suite with scroll sequences of random *k* and margins (must stay 0 differing pixels), the probe. *Risk*: medium (the riskiest correctness change here: the differential tests are the guard).
3. **One pass, no enum, no hashing on the per-cell path.** The recorder writes GPU instances straight into the mapped buffer through a small sink protocol (CPU sink = pixels, GPU sink = instances), so `DrawOp` arrays and the second pass go; glyph cache as a direct table for the common case (scalar < 0x3000 × 4 variants, falling back to the dictionary) holding atlas slots; style/colours resolved once per run of equal style ids. *Effect, estimated*: record 368 → ~150 µs and apply CPU 135 → ~30 µs at 120×40 (to be measured; both backends gain from the table). *Proof*: probe; differential and replay tests unchanged. *Risk*: low-medium (keeps one renderer as the single source of truth only if both sinks are fed by the same loop: that is the design constraint).
4. **Explain the GPU's 0.12 µs per instance before optimising it.** Xcode GPU capture / Metal counters on the probe. Then try, one at a time, measured: backgrounds as one per-cell pass and glyphs with fixed-function premultiplied blending instead of framebuffer fetch (ADR-0024 allows a stated tolerance: measure the largest channel difference against the CPU; adopt only if it is 0 or the owner accepts the number); clipping row fills to the non-glyph area; a smaller glyph quad. *Effect*: unknown until measured; do not promise. *Risk*: colour accuracy (n10): any non-zero difference is the owner's decision.
5. **Fewer frame buffers.** Draw straight into the IOSurface that will be shown (copy the missed rows from the shown one first, which item 2's blit already does) and drop the canvas; use `IOSurfaceIsInUse` to take a free surface, so 2 usually suffice instead of 3; the CPU backend renders into the IOSurface's memory instead of its own `Surface` copy. *Effect*: 4 frame buffers per window → 2-3 (about 22-33 MB less per 120×40 retina window, 110-160 MB at 300×80), and the CPU backend loses a frame-sized memcpy. *Proof*: footprint per window (`bench/tabs-memory.sh`), the surface-renderer test. *Risk*: medium for the CPU backend (writing memory the compositor may read: only surfaces not in use).
6. **Choose the backend per frame by damage, not per window.** With both backends writing the same IOSurfaces (item 5), tiny frames (cursor, one row) go to the CPU sink and large ones to the GPU; `auto` means that. *Effect*: small frames lose the GPU's fixed cost and wake-up (energy, unmeasured); large ones keep the 3.6-4× CPU saving. *Proof*: probe per workload; energy with `powermetrics` (needs sudo: owner) . *Risk*: medium (two writers to one surface, ordered by the ring).
7. **Share the device, queue, pipeline and atlas across windows** (one per process): fewer textures, glyphs uploaded once. *Effect*: memory and start-up per tab; small. *Risk*: low (needs the atlas to be safe for several in-flight frames: item 1).
8. **Measure what has not been**: energy (`powermetrics`, owner-run), latency key → photons, a real ligature font in the differential suite, device loss (force it), CJK-heavy 8K atlas pressure.

**Order of work**: 1 (correctness of concurrency, cheap), 3 (both backends, cheap), 2 (largest win for the most common scroll), 5 (memory, n11), 4 (needs evidence first), 6, 7. Gates for every step: the 12 + 4 differential/replay tests at 0 differing pixels, the probe re-run and its table appended here, the full suite and lint.

**What I do not claim**: any energy figure; that items 2-6 reach their estimates (they are reasoned from the probe's per-op costs, not measured); that the GPU path is "better" for small windows (CPU time equal, wall worse until item 1/6).

## 5. Results

### Item 1: no thread waits for the GPU (done)

`MetalCompositor.apply` is `async`: it commits and suspends on the command buffer's `addCompletedHandler` (no `waitUntilCompleted`; a source rule in
`BannedAPIs` now rejects `waitUntilCompleted`/`waitUntilScheduled`, and failed on the two old calls before the change). Since the actor is free while the
GPU draws, a second `present` can enter: `MetalSurfaceRenderer` hands out turns in arrival order, and `apply` asserts one frame at a time. A test presents 16
frames at once; without the turns it stops on that assertion (watched), with them the surfaces match the CPU renderer's (25 of 25 runs).

Measured (probe, A/B interleaved with the blocking build, 6 rounds each, load 4-14: minimum / median per frame, µs):

| | blocking: wall | async: wall | blocking: process CPU in apply | async: process CPU in apply |
|---|---:|---:|---:|---:|
| 120×40 scroll | 1 912 / 2 543 | 1 173 / 2 199 | 180 / 235 | 169 / 193 |
| 120×40 type 1 char | 286 / 500 | 297 / 361 | 47 / 59 | 49 / 51 |
| 120×40 blink | 274 / 329 | 269 / 329 | 46 / 51 | 48 / 49 |
| 300×80 scroll | 4 929 / 7 775 | 5 247 / 7 535 | 673 / 720 | 640 / 741 |

**No difference in time or CPU beyond the noise**, as it should be: the gain is that no pool thread sleeps for the GPU, not speed. Latency per frame is the
same (the surface must be finished before the layer may show it).

**Correction** to section 2 item 1: the earlier "apply thread CPU" counted only the calling thread. Counted for the whole process (Metal's own threads
included), `apply` costs about **48 µs even for a one-op frame** and ~170-190 µs for a full 120×40 frame. So the GPU path's CPU per full frame is
~373 + 170 ≈ 540 µs against 1 811 (**3.3×**, not 3.6×), and for **small frames the GPU path costs more CPU than the CPU renderer** (blink 4 + 48 against 8;
one character 10 + 49 against 37). That strengthens item 6 (small frames on the CPU).

**Pipelining (several frames in flight): not done, on purpose.** The app keeps one frame in flight per window (`renderInFlight`), and a frame must be
finished before it is shown, so overlapping would only help when record + GPU exceeds the display interval: at 300×80 that is ~2 + 4 ms against 8.3 ms at
120 Hz. Revisit only for very large windows, with a measurement showing dropped frames.

### Item 3, first step: plain operations, a numbered glyph table, no per-cell hashing (done)

Tool: `Benchmarks/Probes/RecordProbe` (`RecordProbe [frames] record|render|feed`), a 120×40 screen scrolling one coloured line per frame (~4 300 operations
a frame), counted with `/usr/bin/time -l` ("instructions retired"; repeat runs agree to 0.1 %; wall times on this machine swung 4× with load and are not
used). `feed` alone (the terminal, no renderer) is 0.13 G and is left in the figures. 3 000 frames:

| step | record (GPU path's CPU side) | render (CPU backend) |
|---|---:|---:|
| before | 21.92 G (7.31 M a frame) | 93.78 G |
| single scalars' glyphs from an array, not a `Dictionary` (`GlyphTable.direct`) | 18.45 G | 90.34 G |
| `DrawOp` a 32-byte value naming its glyph by number; the list appended to the `inout` surface | 16.96 G | 91.23 G |
| the list reserved at the last frame's length | 16.81 G | – |
| the glyph table a value handed down the walk `inout`, not class properties | **15.34 G (5.11 M a frame, −30 %)** | **88.41 G (−5.7 %)** |

Reading:

- **The cost was the walk, not "two passes"** (the plan's premise for item 3 was wrong). With operations not emitted at all (an experiment, reverted)
  record was 14.67 G: emitting cost 1.26 M instructions a frame (~290 an operation: a 65-byte enum copied by `memmove`, a retain of the bitmap, a dynamic
  exclusivity check on the renderer's `recording` property). Now it is ~0.2 M (15.34 − 14.67 G over 3 000 frames, ~50 an operation). What is left,
  ~1 100 instructions a cell, is the walk itself: `drawRow`/`drawCell`, `viewportCell`/`absoluteCell` per cell, `Palette.resolve` and `colors(of:)` per
  cell, `isSelected` per cell, `Attributes` statics read through cross-module addressors, and copies of `Screen`/`Palette` into locals (`sample`).
- **Dynamic exclusivity checks** on the renderer's stored properties (`swift_beginAccess`) were ~10 % of a recorded frame. `@exclusivity(unchecked)` on
  two properties gave 15.19 G, but it turns a check off and Apple documents it nowhere (the compiler's diagnostics page for dynamic exclusivity is a stub
  marked experimental), so it is not used: the table moved into a value (`GlyphTable`) the walk takes `inout` (statically checked), 15.34 G.
- **Glyph numbers**: a recorded frame carries the renderer's glyph table (`DrawFrame.glyphs`, shared, not copied, as long as the caller drops the frame
  before the next is recorded, which `MetalSurfaceRenderer` does) and its generation, unique in the process. `MetalCompositor` keeps an atlas place per
  number (an array, no dictionary or bitmap identity) and writes instances straight into the mapped buffer. The table starts again at 16 384 glyphs, between
  frames, under a new generation, and the compositor then clears its atlas. Tests: numbers are stable across frames; a full table starts again and replays
  exactly; two renderers never share a generation; on Metal, glyphs of a new generation are uploaded again (watched failing with the generation check off:
  wrong pixels).
- Not measured: the effect on the app's frame time or energy; the compositor's own CPU (`apply`) after the change (the instance writing is simpler, but
  `apply` is dominated by Metal's encode and commit, item 1).

### Item 3, second step: the walk (done)

Same tool and workload (3 000 frames, instructions retired, record / render), each step on top of the one before:

| step | record | render |
|---|---:|---:|
| after the first step | 15.34 G | 88.41 G |
| `drawCell` reads through `frame` instead of copying `screen`/`palette` into locals | 15.32 G | 88.28 G |
| (tried, kept only as a base for the next) `Frame` a class: the `Screen` was then copied out of it on every call into it, 3 × 720 bytes | 16.40 G | 89.35 G |
| the walk reads no `Screen` per cell: a row's cells at once (`Screen.viewportRow`, shared storage), the style list and palette taken once | 9.47 G | 82.49 G |
| styles resolved once a frame each (`ResolvedStyle`: colours, flags), decorations only for decorated cells | 7.46 G | 80.42 G |
| the glyph table a `ContiguousArray` (an `Array` of objects checks for a bridged `NSArray` on every read) | 7.35 G | 80.45 G |
| the style cache: one array, the hit inlined | 6.66 G | 80.20 G |
| no selection test when there is no selection | 6.40 G | 79.92 G |
| `Cell`'s accessors `@inlinable` (they were calls across the module boundary) | 6.11 G | 79.65 G |
| glyph placements kept as plain values: recording a glyph does not touch the bitmap (no retain/release) | **5.46 G** | **79.45 G** |

**Recording a frame is 4.0× cheaper than before item 3** (21.92 → 5.46 G, 7.31 → 1.82 M instructions a frame, ~380 a cell with the probe's 4 800 cells).
The CPU backend gains 15 % (93.78 → 79.45 G): its cost is blending pixels, which this does not touch.

How the culprits were found: `sample` for where, then the disassembly of `drawCell` for why. A 720-byte `memcpy` at its entry (the `Frame` struct,
holding the `Screen`, copied per call), calls to `_ArrayBuffer._getElementSlowPath`, `swift_retain`/`release` around the bitmap's fields, cross-module
getters. Lessons: a large struct (`Screen`) must not be on the per-cell path at all, neither by value nor behind a class (both copy it); and a
reference-type array element is best not read per cell.

Correctness: the CPU and Metal suites unchanged and green (Metal at 0 differing pixels); new tests: a window row read at once equals its cells read one by
one (screen, history and packed history, every scroll position); a selected underline keeps its own colour (even one equal to the foreground) and
otherwise takes the swapped foreground (watched failing with a wrong rule I first wrote).

Not measured: app frame time or energy; frames with many styles (a true-colour image: one resolution per style per frame, and the cache's memory, at
most 65 536 entries of 20 bytes); ligature runs and scrolled-back frames in the probe (both covered by tests, not timed).

**Next**: the remaining record cost is mostly `drawCell` itself (appending operations, the per-cell box and cursor arithmetic); item 2 (scroll by moving
pixels) now matters more than shaving it further: a scrolling frame redraws every row.

### Item 2: scrolling moves pixels (done)

- **Core**: `Screen.movedFrom(row:)` says where a row's cells were at the last `clearDirty` when only scrolling moved them (line feed at the bottom, `S`/`T`,
  inserted and deleted lines, scroll regions); a written or blank-new row has none. Dirty marks keep their meaning (a moved row is dirty), so nothing else
  that reads them changes. The host clears the marks in the same lock as it takes the snapshot, so the map is relative to the frame before.
- **Renderer**: when nothing frame-wide changed (no full redraw, no history scrolled back, no selection, no hovered link, now or in the frame before), the
  longest band of rows moved by one offset is moved on the surface (CPU: one `update(from:count:)`, which Apple documents as allowing overlap) or recorded as
  `DrawFrame.move`; moved rows are not drawn unless the cursor is on them now or was on their source row. Their blinking-text marks move with them, so a blink
  phase change draws them as it would have the source.
- **Metal**: a copy between overlapping regions of one texture is undefined (Apple's documentation of the blit copy), so the move reads the surface shown
  last, which holds the canvas as it was; no extra texture.
- **Found on the way**: a wide character wrapping at the last column did not dirty the row it left (fixed with its own test, commit before this one); the
  differential tests now cover blinking text, the blink phase, and recorded frames replayed one after the other.
- **Guards**: core tests for the map; a recorded scroll frame moves 5 rows and draws 2; Metal agrees at 0 differing pixels on scrolls in the rig and through
  the app's ring of three surfaces; the CPU and recorded differential tests (moves in over 100 of their frames) plus 60 further seeds, 180 000 frames, with
  no difference. Breaking each rule fails them: dropping the "cursor now" or the "cursor before" exclusion, or the blink-mark move, fails a differential
  test; moving from the wrong ring surface fails the ring test. A third rule I first wrote (blinking source with a phase change) changed nothing when
  removed: the row is redrawn by the blink rule anyway, so it was taken out.

Measured, RecordProbe (120×40, one line a frame), A/B of the commit before and this one, interleaved, 4 rounds of 3 000 frames, load 4.7-6:

| | before | after |
|---|---:|---:|
| record, operations a frame | 4 300 | 113 |
| record, instructions | 5.49-5.50 G | 0.41 G (feed alone is 0.13 G of it) |
| CPU backend, instructions | 79.6-79.7 G | 8.1 G |
| CPU backend, user CPU time, per round | 4.99 / 6.51 / 7.64 / 8.83 s | 0.83 / 1.30 / 1.54 / 1.69 s (**5.0-6.0× less**) |

The CPU backend's remaining cost is mostly the move itself, memory bound (the probe's surface is ~11 MB). The renderer-stages probe (one run, loaded,
indicative): 120×40 scroll 1 line, CPU render 293 µs (1 971 µs earlier the same day), GPU execution 610 µs (1 408), process CPU in `apply` 92 µs (309).

Not measured: the app end to end (the CPU path also copies the moved band to the shown IOSurface, as it did before, when every row was dirty), energy,
floods of many lines a frame (a gain while *k* is under the row count), scrolling with a selection (falls back to drawing, by design).

**Next**: item 5. The GPU path now copies two frames' worth per scroll (the move into the canvas, the changed rows out to the shown surface): drawing
straight into the surface to be shown, after moving into it from the one shown, would do one copy and drop the canvas texture (memory, n11).

### Item 5, GPU part: no canvas (done)

`MetalSurfaceRenderer` draws straight into the next surface of its ring of three. In one command buffer: the rows that surface missed are copied from the
surface shown last (less the rows the frame's move writes), the move is copied from it, then the operations are drawn. The canvas texture is gone.

- Guards: the ring tests (frames through the rotation, a scroll every frame, concurrent presents, resize) agree with the CPU backend pixel for pixel;
  skipping the missed-rows copy fails 18 of their checks; a test pins 3 frame buffers per window (it was 4: watched red); the range subtraction has edge tests.
- Memory, the app with the GPU renderer, one default-size window, `footprint` after 10 s, 2 rounds each: "IOAccelerator (graphics)" **10 MB → 5.28 MB**
  (both rounds), total 41 / 46 MB → 36 / 36 MB. The canvas was one frame buffer: 10.9 MB for a 120×40 window at the probes' 28 px font, 54 MB at 300×80.
- Time, `present` end to end (it awaits the GPU), 300 scroll frames, A/B against the commit before, 4 rounds each, load 6-8, median / 10th percentile µs:
  120×40 no difference beyond noise (p10 558-618 before, 565-630 after); 300×80 p10 lower in every round (1 811 / 1 825 / 1 895 / 2 084 before,
  1 534 / 1 538 / 1 544 / 1 819 after). Process CPU per frame unchanged (78-88 µs both), as expected: the CPU side did not change.

Not done yet from item 5: taking a free surface with `IOSurfaceIsInUse` so that two usually suffice, and the CPU backend drawing into the IOSurface's memory
instead of its own `Surface` (it keeps a frame-sized copy and copies the changed rows every frame).
