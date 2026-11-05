> Snapshot of the investigation written on 2026-11-05 before the repositories existed. Where it disagrees with the ADRs or roadmap, those win.

# A declarative terminal UI framework, and a Swift terminal — investigation

Written 2026-11-05. Loose file at the workspace root (next to `ask-wishes.md`) so that no repository's doc-law tests are touched.
Move it into a roadmap entry / ADR once the open decisions in §7 are answered.

Evidence labels: **[read]** I read the code or docs; **[probed]** I ran something; **[recalled]** from memory, not checked;
**[unverified]** a proposal or guess that needs a probe before anyone acts on it (TerminalKit white paper §0).

Sources read: `ask`, `TerminalKit`, `Atelier` (incl. `Apps/KittyCode`), `aemi` (local); OpenSwiftUI / OpenAttributeGraph / SwiftTerm /
kitty / swift-subprocess / swift-system (shallow clones in `/tmp/ref`, may be gone); the SwiftUICore `.swiftinterface` of the installed
Xcode SDK; Apple docs for UIKit/Observation; Ghostty's repo tree via `gh`. "kittycode" is Atelier's terminal code editor (it is where
TerminalKit was extracted from), not the kitty terminal; kitty was read separately.

---

## 1. What exists today (the starting point is strong)

### TerminalKit — the engine is already good [read]
- `RenderPipeline`/`ScreenBuffer`: 16-byte `PackedCell` (inline grapheme ≤ 8 bytes, process-wide `StyleTable` ids), diff renderer,
  scroll-region detection (DECSTBM/SU/SD), synchronized output, dirty regions. Measured steady state: 0 mallocs per frame, ~2.3 ns per
  unchanged cell (ADR-0021).
- `RenderLoop<Composer>`: a render **thread** draws the *newest* `Sendable` state; input has its own thread; handling a key costs ~0.01 ms
  regardless of frame cost (ADR-0023/0026, with a four-design stress test).
- Input: zero-alloc decoders (kitty keyboard 105 ns, SGR mouse 127 ns), `PointerRecognizer` (clicks/drags/wheel over named regions),
  probes for capabilities, `TerminalSession` modes as a unit.
- Text/Markdown/Unicode width tables, selection with provenance, folding.
- The doctrine (white paper) is strict and enforced: measure everything, zero-alloc hot paths, `Mutex` not locks, Swift 6 + strict memory
  safety, deterministic tests. Anything below must live by it.

### ask's UI — fast, but every feature is hand-wired [read]
- `AskTUI`: 199 files / 12.4k lines. `ScreenComposer` (imperative, 25 `+Extension` files), `ScreenController` (~50 extensions), a
  `FrameGeometry` family that the pointer code uses to resolve clicks, `WindowedLayout` for the transcript.
- The "questions" feature alone is mentioned in **43 of 199 files** (grep count; includes incidental mentions, so it overstates the
  files you *must* touch, but not by an order of magnitude). A new component means: state in `ScreenState`, an event in `ScreenEvent`, a
  `ScreenComposer+X` to draw, a `FrameGeometry+X` so clicks resolve, a `ScreenController+X` for keys, plus hover/focus/selection glue.
  That is the cost the framework must remove — not the speed, which is already good.
- Performance machinery worth *keeping*: a composer that rewrites only changed rows, a flattened wrapped-line cache that re-wraps only
  from the first changed item, geometry handed back from the render thread (`FrameBox`) so a click means what was drawn.

### KittyWidgets — a first SwiftUI-like attempt, with lessons [read + one count]
`Atelier/Apps/KittyCode/Sources/KittyWidgets` (4.8k lines): `View`, `@ViewBuilder`, `VStack/HStack/ZStack`, `@State`, `Environment`,
`FocusEngine`. Not used by ask. Its problems are precisely what the new framework must not repeat:
1. **No identity, no retained tree.** `@State` is a `Mutex` box created inside the struct; when the view value is rebuilt the box is
   rebuilt, so state does not survive a re-render unless something outside owns it. SwiftUI keeps state in the graph, keyed by identity.
2. **Dynamic dispatch by casting.** `ViewRenderer` (1,675 lines) walks the tree with `view as? any _ScrollViewProtocol`, `_TupleViewProtocol`,
   … (18 cast sites). Existential casts per node per frame are the opposite of the static `_makeView` dispatch SwiftUI uses.
3. **Whole-tree re-render, no invalidation**, only a view-model `invalidate()` callback.
4. `body: Never` leaf hack and `fatalError()` in every primitive.

---

## 2. SwiftUI internals — what to copy, what to drop

Basis: OpenSwiftUI (a clean-room reimplementation whose source is readable [read]) cross-checked against the real
`SwiftUICore.swiftinterface` in the installed SDK [read], Apple's WWDC sessions (Demystify SwiftUI / SwiftUI performance) [recalled].
OpenSwiftUI is a reimplementation: where it and real SwiftUI could differ I treat its behaviour as a hypothesis, not as Apple's.

| Mechanism | How it works | Take it? |
|---|---|---|
| **Views are cheap value descriptions**; identity is *structural position* (type + position in `ViewBuilder` result, or explicit `.id`) | `TupleView`, `_ConditionalContent`, `ForEach` give the static shape | **Yes** — the core idea |
| **State lives outside the value**, in the graph, keyed by identity | `@State` storage is attached to the node, survives body re-evaluation | **Yes** (KittyWidgets got this wrong) |
| **Static dispatch**: `View._makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs` — each view type builds its own subgraph; no runtime casts | Interface lines for `Layout._makeLayoutView` confirm the shape | **Yes**, as `static func _makeNode` generated by a macro/default |
| **AttributeGraph**: a DAG of typed attributes; `Rule`/`StatefulRule`; dependencies recorded *by reading* during rule evaluation; mark → sweep → recompute lazily, with value comparison (`compareValues`) to stop propagation | OpenAttributeGraph is ~C++ (`Graph.cpp`, `table.cpp`, `zone.cpp`) over Swift runtime metadata (`Metadata`, `TupleType`) | **Take the idea, not the implementation.** It relies on reading Swift field metadata and C++; for a terminal we can get most of the win with node-level dirty bits + Equatable skipping (§4.2). Re-deriving AG is a multi-month project with weak payoff at ≤ a few thousand nodes |
| **Environment** flows down (property list of typed keys); **Preferences** flow up (`PreferenceKey` + `reduce`) | `_GraphInputs.environment`, `PreferencesInputs` | **Yes** — preferences are how a child tells a container "I am focusable / I want this status text / I am a hit region" without wiring |
| **Layout = propose / choose / place**: parent proposes a (nilable) size, child returns its size, parent places. Public `Layout` protocol: `sizeThatFits`, `placeSubviews`, `makeCache`, `spacing`, `explicitAlignment` (confirmed in the interface) | `StackLayout`: children sorted by *flexibility*, remaining space split evenly among those not yet fixed, in priority groups | **Yes** — and integers in cells make it simpler and exact |
| **Transactions/animation** (`Transaction`, `Animatable`, interpolation) | Large (Animation = 11k lines in OpenSwiftUI) | **Defer.** Terminals need: spinner/timeline clocks and maybe eased scroll. Not a general animation engine |
| **Gestures** (recognizer state machine, `Gesture` composition), accessibility tree | 9.7k + 4k lines | **Subset**: tap/drag/hover/scroll over `PointerRecognizer`; accessibility via a semantic tree is a later bonus (screen readers read terminals poorly anyway) |
| **Render**: view graph → `DisplayList` → renderer (separate phases, can be async) | `ViewGraph.updateOutputs`, `ViewRendererHost` | **Yes, simplified**: tree → damaged cell regions → `ScreenBuffer` |
| Update loop: host calls `updateGraph()` (root view, environment, size, safe area, focus…) then `updateOutputs(at: time)` on a run-loop turn | `ViewRendererHost.updateGraph/render` | **Yes**: one "turn" per submitted state, coalesced — already what `RenderLoop` does |

**What costs SwiftUI performance (and so what to avoid)** [recalled]: bodies that run because a too-wide dependency changed, `AnyView`
erasing structure, identity churn, and large `ForEach` without laziness. The terminal answers are cheap and local: narrow dependencies
(§4.2), no `AnyView` in the hot path (a typed `Slot<some View>` or an enum node), stable ids, and lazy containers for the transcript.

## 3. UIKit internals — what to copy

UIKit is closed; the following is from Apple docs [read] and general knowledge [recalled]; nothing was reverse-engineered by me.

- **Invalidate, don't redraw.** `setNeedsLayout/Display/UpdateProperties` set bits and are *coalesced to the end of the run-loop turn*.
  iOS 26 formalizes the order **`updateProperties()` → `updateConstraints()` → `layoutSubviews()` → display**, and (docs, read) *automatic
  observation tracking*: reads of `@Observable` properties inside `updateProperties()`/`layoutSubviews()` register the view for
  re-run when they change. That is exactly the model to adopt: **three phases (properties → layout → draw), each with its own dirty bit
  per node, each tracking what it read.**
- **Responder chain + hit testing**: `hitTest` walks front-to-back by frame; events go to first responder and up the chain; unhandled
  events fall through. Adopt for keys (focused node → ancestors → app) and pointer (hit node → ancestors).
- **Focus system**: focus groups/regions and a focus engine that moves by direction or tab order. Adopt (KittyWidgets' `FocusEngine`/
  `FocusMap` already point the same way).
- **Layers/compositing** is what a GPU gives UIKit; a terminal has one flat cell grid, so overlap = painter's algorithm + damage rects.
- Auto Layout (Cassowary) — **do not adopt.** Proposal/report is cheaper, deterministic and fits a text grid.

---

## 4. The framework (working name `TerminalKitUI`; see §7 on naming)

### 4.1 Principle
SwiftUI's *authoring model* (value-type views, `body`, modifiers, `@State`, environment, preferences, `Layout`) on top of **UIKit's
*update model*** (retained nodes, coalesced three-phase invalidation, explicit hit testing/focus), drawing into the existing
`ScreenBuffer` through the existing `RenderLoop`. No new terminal I/O: TerminalKit stays the engine.

### 4.2 Architecture (all [unverified] proposals; the numbers in §4.5 are the bar, not claims)

```
 app state (Sendable snapshot, as ADR-0026)      input thread (TerminalKitInput)
        │ submit(newest wins)                          │ events
        ▼                                              ▼
 ┌──────────────────────── render/UI thread (owns the tree) ───────────────────────┐
 │ 1 reconcile:  root View value ─► Node arena (identity by position/.id)          │
 │ 2 properties: dirty nodes re-run body; deps = selectors + Observation reads     │
 │ 3 layout:     propose/choose/place, integer cells; per-node size cache          │
 │ 4 draw:       damaged rects → ScreenBuffer (PackedCell) → DiffRenderer.flush    │
 │ 5 publish:    immutable HitMap/FocusMap snapshot → FrameBox (input resolves)    │
 └──────────────────────────────────────────────────────────────────────────────────┘
```

1. **Node arena.** Nodes are stored struct-of-arrays in a pooled arena (index = `NodeID`), not class instances per view: no ARC traffic,
   cache-friendly traversal, zero allocation once warm. A node holds: view-type tag, identity key, parent/child links, dirty bits
   (`properties`, `layout`, `draw`), cached `sizeThatFits` for the last proposal, frame, state slots.
2. **Static dispatch, no casts.** Each view type provides `static func makeNode` / `update(node:with:)`. A `@View` macro (we have
   `AemiMacros`/`AemiMacroSupport` [read the target names, not their contents]) synthesizes: structural `Equatable`, the stored-property
   layout for `@State`, and the dependency declarations. Composition views (`body`) recurse; primitives (`Text`, `Stack`, `Scroll`) implement
   `makeNode` directly. This replaces KittyWidgets' `as? any _XProtocol` chain.
3. **Skip by equality.** When a parent re-runs its body, a child whose input value is `==` to the stored one is not touched (SwiftUI does this
   via `compareValues` on field metadata; we do it with macro-synthesized `==`, which is cheaper and safe).
4. **Dependencies, narrowly.** Two sources invalidate a node's `properties` phase:
   - *Snapshot selectors*: `@Query(\.jobs)` reads a projection of the app snapshot; on each new snapshot the framework compares the
     projection (`Equatable`) and invalidates only dependents. Matches ADR-0026 (state arrives as whole `Sendable` snapshots, newest wins).
   - *Local models*: Swift Observation (`withObservationTracking`) around `body`, as UIKit does in `updateProperties`. **Open question**: whether
     Observation's per-read tracking allocates on the hot path (it creates a tracking context per evaluation) — must be measured against
     the zero-allocation budget; if it does, use selectors only and keep Observation for non-hot UI models.
   - `@State` writes set the node's bit directly (O(1), no allocation), then wake the render thread (existing semaphore).
5. **Layout.** `Layout` protocol as SwiftUI's, with `Int` cells. `VStack/HStack` use the flexibility-ordered even split. Text measure is
   cached by (content identity, width) using `TerminalKitText` (grapheme-aware, widths from the tables in ADR-0024). Bottom-aligned
   transcript = `LazyVStack(anchor: .bottom)` over the existing `WindowedLayout`, so only visible rows have nodes (the big-win
   virtualization; ask does this today by hand).
6. **Draw & damage.** The back buffer persists across frames (as `ScreenComposer` assumes today). A node redraws only if its draw bit or its
   rect's damage says so; overlapping siblings (`ZStack`, overlays, pickers) repaint in z-order inside the damaged rect only. The existing
   `DiffRenderer` then emits bytes, including scroll-region detection, unchanged.
7. **Input.** A `HitMap` (rects → node ids + handlers + selectable-text provenance) and `FocusMap` are rebuilt only when layout changed and
   published immutably via `FrameBox` — the pattern ask already uses. Pointer: tap/drag/hover/wheel built on `PointerRecognizer`. Keys:
   `.onKey`/`.keyCommand` handlers along focused → ancestors; default actions (Space/Enter/Tab) belong to controls. Selection uses the
   `Source` provenance of `Text` (ADR-0030) so copy keeps working across components.
8. **Concurrency.** The tree is owned by the render thread (like UIKit's main thread). Everything crossing in is `Sendable` and coalesced;
   nothing blocks input (ADR-0026 conclusions hold). `@State` writes from input handlers are queued to the tree owner, not made under a
   lock mid-frame.
9. **Time.** A `TimelineView`-style clock node: wakes the loop only while something visible animates (spinner, elapsed time), tying into
   roadmap 0025 (idle = no wakeups). Colour animation must respect ADR-0021's "StyleTable never shrinks" consequence.
10. **Test harness.** Headless: build tree → layout → draw into a `ScreenBuffer` → assert on the text/style grid; plus byte-level
    through `MockTerminalConnection`; plus (once §5 exists) replay the emitted bytes into the real emulator and compare grids — which
    turns the current "oracle model" into a closed loop.

### 4.3 Authoring target (the bar for "easier to add components")

```swift
struct QuestionTabs: View {
    @Query(\.pendingQuestions) var questions
    @State var tab = 0
    var body: some View {
        VStack(spacing: 0) {
            TabBar(selection: $tab, items: questions.map(\.title))
            ChoiceList(questions[tab].choices, selection: $answers[tab], multi: questions[tab].multi)
            NoteField(text: $notes[tab])
        }
        .keyCommand(.enter) { advance() }
        .focusScope()
    }
}
```
Today the equivalent is the 43-file spread above. The check is behavioural: re-implement the question panel and the picker this way and
count files/lines changed to add them, and compare p50/p99 compose time and mallocs against the current composer on the same states.

### 4.4 Component set needed for ask (from `docs/screen.md`) [read]
`Text`/styled runs, Markdown block (TerminalKitMarkdown), code block with highlight + fold, diff block, tool block (header + status +
fold), `TextEditor` (PromptEditor model + markdown-aware editing), completion picker (`/`, `@`, `#`), `List/Picker` (models, sessions,
notes), question tabs, approval panel, sidebar tree (threads/jobs), status line with leading spinner + trailing segments, overlay/modal,
scroll-follow-tail, link (OSC 8), selection/copy, toasts (clipboard notice). Wishes in `ask-wishes.md` that this makes cheap: session
take-over list, confirmation pickers, color theming per block kind (purple for ask/config blocks).

### 4.5 Budgets (to be measured, not assumed) 
Reference numbers exist in `TerminalKit/Benchmarks/REFERENCE.md`. Proposed gates, same harness (`package-benchmark`), release only:
- keystroke → frame composed: p99 ≤ today's `ScreenComposer` p99 on the same state (the regression bar), 0 mallocs steady-state;
- streamed delta into a long transcript: cost ∝ visible rows, not transcript length;
- new component = tests + one file.
If the declarative layer cannot match the hand-written composer on ask's three hot scenarios (keystroke, streaming delta, idle), the
answer is to narrow the framework (static layouts, no Observation), not to relax the bar.

### 4.6 Migration (strangler, each step shippable and benchmarked)
1. `TUICore` + headless harness (no ask changes).
2. `HostedRegion`: embed a declarative subtree inside the current `ScreenComposer` (compose-into-rect + hit/focus export). Port the
   **status line**, then **question panel**, then **pickers** (smallest, self-contained, most-wished).
3. Prompt editor, then sidebar tree.
4. Transcript last (it carries the most hand-tuned performance machinery); keep `WindowedLayout` and fold/selection semantics.
5. Delete `ScreenComposer+*`/`FrameGeometry+*` only when nothing references them.
KittyWidgets: salvage `FocusEngine`/`FocusMap`/`KeyMap` ideas and `TextEditor`/`TreeView` logic; do not extend its renderer.

---

## 5. The Swift terminal (roadmap 0026 "AemiTerminal" already says: headless first, then macOS app, then iOS)

### 5.1 What kitty does that matters [read from /tmp/ref/kitty, commit bdbf9f5]
- **Threads**: child I/O + parsing in one thread, rendering in the main thread (`child-monitor.c`, 2.6k lines); docs/performance.rst says
  the same. `input_delay`/`repaint_delay` are tunable artificial delays (docs/performance.rst; it mentions `input_delay` defaulting to 3 ms; I did not check the repaint default).
- **Parser**: `vt-parser.c` with a SIMD fast path for plain text runs (`simd-string.c`); docs claim ~2× the throughput of the next
  terminal (kitty's own benchmark, a vendor number — not independently reproduced).
- **Cells**: split in `CPUCell` (12 B: codepoint-or-index, hyperlink id, multicell scale/width bits) and `GPUCell` (20 B: fg, bg,
  decoration colour, sprite index, attrs) — colours inline, so any number of distinct colours costs nothing in a table [read `line.h`].
- **Rendering**: glyph rasterized once into a GPU sprite atlas; per-frame only cell data is uploaded; shaders in `kitty/shaders/*.slang`
  (cell, graphics, border, trail…).
- **Protocols** worth supporting because ask already speaks them: kitty keyboard, kitty graphics (`graphics.c`, 3.2k lines, animation,
  placement, z-index), **text sizing (OSC 66, since 0.40 — docs)**, OSC 8, OSC 52, OSC 133 (shell integration/semantic prompts), synchronized
  output, DECRQM, pointer shapes, desktop notifications, unscroll. (docs/*.rst listing.)

### 5.2 Prior art in Swift/Apple space
- **SwiftTerm** (migueldeicaza, MIT, ~75k lines, active [read]): full emulator + AppKit/UIKit/headless frontends, Metal renderer option,
  kitty graphics/keyboard/clipboard, Sixel, `HeadlessTerminal`, vtebench ports in `PERFORMANCE.md`.
- **libghostty-vt** (Ghostty, Zig, MIT; "zero-dependency C and Zig library", README [read]; C headers under `include/ghostty`):
  embeddable VT core; Swift wrappers exist (`libghostty-spm` found by search — not inspected).
- **Apple/swiftlang**: `swift-subprocess` has no PTY API that I could find (grep for openpty/forkpty/pseudo found one comment about a
  controlling pseudo-terminal signal, no implementation); `swift-system` has no `openpty`. So PTY handling is ours, via Darwin.

### 5.3 PTY: de-risked [probed]
Probe (`/tmp/probe/spawnpty.swift`, this machine): `openpty` + `posix_spawn` with `POSIX_SPAWN_SETSID` and `dup2` file actions to 0/1/2
runs `/bin/sh` with a controlling tty: `tty` printed `/dev/ttys012` and `ps` showed `TPGID == PID`, i.e. the child is the foreground
group of that tty. So no `fork` in a multithreaded Swift process is needed. **Not yet probed:** job control inside the child
(Ctrl-Z/`fg`), window-size change delivering SIGWINCH, `login`/utmp, `TIOCSCTTY` on other macOS versions, hand-off of the master fd to
a reader thread under backpressure. `TerminalKit/Tests/TerminalKitIOTests/PseudoTerminal.swift` already wraps `openpty` for tests.

### 5.4 Architecture (all [unverified])
```
AemiTerminalCore (no UI, no AppKit; Linux-able per TerminalKit roadmap 0024)
  VTParser      Williams state machine over RawSpan<UInt8>; printable-ASCII/UTF-8 run fast path using AemiKernels (UTF8/Find/ByteSet)
  Screen        pages of rows; PackedCell-like cells; reflow on resize; scrollback ring; alt screen; semantic-prompt marks
  Modes/Reports DECSET/DECRQM, DA1-3, XTVERSION, OSC 4/10/11 queries, kitty keyboard flags, mouse modes, sync output
  Protocols     kitty graphics, text sizing (OSC 66), OSC 8/52/133, (Sixel later)
  Pty/Process   openpty + posix_spawn(SETSID); reader thread with backpressure; resize → TIOCSWINSZ
AemiTerminalKit (AppKit)
  Renderer      glyph atlas + Metal instanced cell draw (kitty/ghostty model); CoreText shaping/fallback; CALayer/CoreGraphics first as a baseline
  Input         NSTextInputClient (IME), key encoder (legacy + kitty protocol: the *encoder* side of TerminalKitCodecs' decoder)
  Shell         windows, tabs, splits, selection, search, scrollback UI, URL/paths click (reuse ask's PathLinks), themes following system appearance
AemiTerminal (executable)  headless: spawn + keys/resizes in, screen/cells out (the orchestratable entity of roadmap 0026 phase 1)
```
Key decisions and why:
- **Cell storage cannot reuse the process-wide `StyleTable` as is.** ADR-0021 records that it never shrinks and is fine for "tens of
  styles"; an emulator receives arbitrary programs' colours (gradients, truecolor images in half-blocks) → millions of styles. Use inline
  colours like kitty, or a per-screen ref-counted style set like Ghostty's pages. This is a real difference between the two projects, and
  the first thing to probe.
- **Build the core ourselves, and use SwiftTerm and libghostty-vt as differential oracles and benchmark baselines** (vtebench workloads are
  already ported in SwiftTerm's `Tools/SwiftTermBenchmarks`). Reason: the white paper's constraints (zero-alloc hot path, strict memory
  safety, Mutex/Span) and the goal of one shared Unicode/width/style stack with TerminalKit. Counter-argument: 75k lines of working
  emulator exist; adopting SwiftTerm's core would reach the macOS app much sooner. **This is the main decision for you (§7).**
- **Conformance is measured**: `vttest`, `esctest`, `vtebench`, plus differential fuzzing (same byte stream into ours, SwiftTerm, and
  libghostty-vt; compare grids). TerminalKit's DECRQM harness that already drives kitty/ghostty/wezterm/Terminal.app
  (`Scripts/verify-reset-ladder.py`, roadmap 0002) is the model for real-emulator tests.
- **Phase 1 is also the framework's test oracle.** `ask` probes run on pyte, which mis-draws some incremental updates (roadmap 0026 text).
  A trusted headless emulator closes the bytes→grid loop for the TUI framework: render → bytes → emulator → grid == expected buffer.
  This is why the order is **emulator core first (headless), framework in parallel, macOS app last.**
- **Latency target**: kitty's design (separate parse thread, atlas, tiny uploads) is the reference; our measure is key-to-photon, which we
  cannot measure without hardware (Typometer-style / camera); until then measure key→screen-model and parse throughput only, and say so.

### 5.5 Phases and gates
| # | Deliverable | Gate (measured) |
|---|---|---|
| T0 | Probes: style-table policy under truecolor stress; reader-thread backpressure; resize reflow cost; SIMD-ish run scanning with `AemiKernels` vs byte loop | numbers in a diary entry |
| T1 | `VTParser` + `Screen` + `HeadlessTerminal`; red tests from `esctest`/`vttest` fixtures first | pass list with the gap list published; vtebench throughput vs SwiftTerm and libghostty-vt in the same harness; 0 mallocs/MB steady state |
| T2 | PTY host + the orchestration API (spawn, keys, resize, screen snapshot, replies) and a CLI | runs ask end to end; replaces pyte in ask's interface probes |
| T3 | Protocol set ask needs: kitty keyboard, OSC 4/10/11, sync output, OSC 8/52/133, mouse | ask's capability probes (`TerminalProbe`) answered correctly |
| T4 | macOS app, CoreGraphics renderer first, then Metal atlas | frame time p99; scroll smoothness; idle wakeups ≈ 0 (roadmap 0025) |
| T5 | kitty graphics + text sizing; tabs/splits; themes follow system appearance | graphics protocol conformance suite |
| T6 | iOS (touch, key row, SSH host) | out of scope until T4 ships |

---

## 6. How the two reinforce each other
- Framework `DiffRenderer` output is the best real-world fuzz corpus for the emulator; the emulator is the first trustworthy oracle for the
  framework (§4.2.10, §5.4).
- Both share `PackedCell`/width tables/`AemiUnicode`/`AemiKernels`; both obey one white paper.
- The terminal can implement protocol features (text sizing, kitty graphics) that the framework then exposes as components (`Heading`
  via OSC 66, `Image`), which kitty-only today.
- Atelier's KittyCode could move to the framework (its `KittyWidgets` is the abandoned earlier attempt).

## 7. Open decisions (need you) and unverified claims

Decisions:
1. **Emulator core: own Swift core (my recommendation, with SwiftTerm/libghostty-vt as oracles) or adopt SwiftTerm?** Adopting is months faster to a
   working app; owning fits the doctrine and the shared stack.
2. **Where the framework lives**: new `TerminalKitUI*` targets inside TerminalKit (shares tests, benchmarks, doctrine; ADR-0007 says generic
   tools belong in aemi, but this is terminal-specific) vs a new repo. I recommend inside TerminalKit, split into
   `TerminalKitUICore` / `Layout` / `Controls` so ask links only what it uses (link weight, white paper).
3. **Name** of the terminal (`AemiTerminal` per roadmap 0026; ask ADR-0001 once used the name for the stack) and of the framework. `AemiUI`
   is taken (it is the SwiftUI component package; I read only its stub and `FixedSize.swift`).
4. **Floor**: macOS 26 (current rule) is fine for the app; the emulator core targeting Linux (roadmap 0024) changes which Darwin calls may
   appear in it.

Not verified by me:
- Everything in §4.2 and §5.4 is a design, with no code written and no benchmark run.
- Whether Observation tracking allocates per `body` evaluation on this toolchain (Swift 6.4.2 here).
- That a retained-tree framework can match the hand-tuned composer's p99; the migration plan is built so this is tested on small surfaces first.
- vendor numbers (kitty's throughput table) and SwiftTerm's quality/perf: not reproduced.
- UIKit behaviour beyond Apple's docs; OpenSwiftUI == SwiftUI behaviour.
- `AemiMacros` fitness for the `@View` macro (only the target names were seen), and whether `libghostty-vt` is stable enough to link.
- Nothing was built or run in the three repos; no repo was modified. The only files I created are this document and probes under `/tmp/probe`.

---
---

# Addendum (round 2, 2026-11-05): revised constraints, reverse engineering started, dependency map

This addendum **supersedes** §7 decisions 1–4 and any earlier statement it contradicts. Labels as before.

## A. Constraints as now stated
1. Reverse engineering SwiftUI/UIKit binaries is allowed and encouraged; the *knowledge* is ported, no Apple code is copied into our tree and
   no extracted binary is committed anywhere.
2. Multi-month work is fine, so the plan below optimises for the right architecture, not the shortest path.
3. **Names:** the SwiftUI-like package is **`TerminalUI`**. The terminal's name is **undecided**. `Aemi*` names are for dependencies only, never end products.
4. The terminal: **kitty graphics compatible and every modern feature** (keyboard, text sizing, OSC 8/52/133, sync output, …), macOS first,
   **Linux a real target**, priorities: performance, safety, resilience, reliability, security; plus **color accuracy, GPU acceleration, typography**.
5. **Depend only on our own tooling** (the Aemi family and our other packages), promoting generic pieces into Aemi when a second consumer is plausible.

Consequences I draw (tell me if wrong):
- Former decision 1 is settled: **we write our own emulator core.** SwiftTerm, libghostty, kitty, ghostty and wezterm are *oracles run as
  external processes in tests and benchmarks*, never linked.
- **Platform APIs are not "dependencies"**: libc, Metal/CoreText/CoreGraphics/AppKit on macOS; the kernel PTY, Vulkan loader, fontconfig
  *discovery* and Wayland/X11 on Linux. I assume these are allowed; anything above them is ours. (Decision needed if you want to go further, e.g. no fontconfig.)
- Apple/swiftlang *packages* (swift-system, swift-collections, swift-crypto, swift-subprocess, swift-argument-parser, swift-syntax) appear in
  ask's/aemi's pin sets today. For the new code I'd use them **only where aemi already depends on them**, and prefer promoting an Aemi
  equivalent otherwise. Decision needed on whether existing pins stay acceptable.
- TerminalKit/ask already follow this; `TerminalUI` and the terminal sit in the same dependency graph.

## B. Names
- **`TerminalUI`**: fine under `g-cqd`, but note two public Swift projects with the same name exist: **chriseidhof/TerminalUI (323★)**, a SwiftUI-like
  terminal experiment, and 1amageek/TerminalUI [read from `gh search repos`]. Not a legal issue; a *module-name* clash only if someone
  imports both, and Chris's is useful prior art to read (not yet read). If you want zero ambiguity the module can be `TerminalUI` with a
  distinct product/repo name.
- **The terminal**: left open. A GitHub-Swift search found no obvious squatters (only unrelated hits) for these candidates, which fit
  "cell grid / typography / GPU": *Tessera* (a tile of a mosaic: the cell grid), *Vellum* (parchment: type), *Lectern*, *Loom*, *Kerning*.
  `Loom` has a 358★ Swift project (EthanLipnik/Loom); `Vellum` small ones. Only GitHub Swift search was checked, not trademarks or App Store.
  Until chosen, docs say "the terminal".

## C. Reverse-engineering: pipeline built and verified [probed]
Machine: macOS 27.0.1 (26A434), SIP on, Xcode with Swift 6.4.2.
1. **The OS frameworks live only in the dyld shared cache** (`/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e*`, 2.3 GB).
2. **Extraction works with Xcode's own bundle**: `dlopen` `Xcode.app/.../Platforms/XROS.platform/usr/lib/dsc_extractor.bundle` and call
   `dyld_shared_cache_extract_dylibs_progress(cache, outdir, progress)`: 4,088 images, 6.4 GB, about 30 s (`/tmp/re/ext.c`). It is all-or-nothing, and the disk has
   ~28 GB free, so the script extracts, copies the images we study and deletes the rest.
3. **Kept (169 MB, `/tmp/re/keep`, arm64e):** `SwiftUI` (56 MB), `SwiftUICore` (42 MB), `AttributeGraph` (0.4 MB, the dependency engine),
   `libswiftObservation`, `QuartzCore`, `CoreText`, `CoreGraphics`, and **`UIKitCore`** (58 MB, the Mac Catalyst copy at `/System/iOSSupport/...`; macOS
   has no AppKit-style UIKit, but the Catalyst UIKitCore is the real one).
4. **Tools that work here:** `nm`, `dyld_info` (reads straight from the cache, no extraction needed for symbols/exports/platform), `otool`, `llvm-objdump`,
   `swift-demangle`, `c++filt`, `lldb`. Not installed: Ghidra, Hopper, ipsw, class-dump. (A disassembler/decompiler decision is open; `llvm-objdump` plus our own
   notes is enough to start, Ghidra would speed the deep parts.)
5. The simulator runtimes (`iOS 27.2`) are present as disk images but not mounted for me; not needed since Catalyst UIKitCore exists.

### First findings (symbol level only; behaviour not yet read from disassembly)
`AttributeGraph` exports 1,800 symbols; C++ classes `AG::Graph`, `AG::Subgraph`, `AG::Node`, `AG::Graph::Context`. What the names say:
- **`Graph`**: `add_attribute/add_input/remove_input_edge`, `propagate_dirty`, `mark_pending`, `mark_changed`, `update_attribute`,
  `any_inputs_changed`, `compare_edge_values` (value comparison on edges stops propagation: confirms "dirty then compare" rather than
  push-recompute), `add_indirect_attribute` (+ `indirect_attribute_set_dependency`: indirect nodes = references into other nodes, the basis of
  keypath/projection attributes such as `@State` and `Binding` slices), a **profiler and trace recorder** (`begin_update`/`end_update`,
  `TraceRecorder::add_edge`, `begin_invalidation`) and a debug `description_graph_dot`.
- **`Subgraph`**: owns nodes (`add_node`, `insert_attribute`, `unlink_attribute`), has a **parent/child tree** (`add_child`, `ancestor_of`),
  **dirty flags that propagate up/down the tree** (`add_dirty_flags`, `propagate_dirty_flags`, `set_flags`), a per-subgraph **node cache**
  (`cache_fetch/insert/collect`: memoised attributes keyed by value, which is how identical subtree computations are shared), a **`tree`**
  (`begin_tree/end_tree/add_tree_value`: the structure the view hierarchy is recorded in for debugging/accessibility), and **bulk
  invalidation** (`invalidate_now`, `invalidate_and_delete_`: when a view disappears its whole subgraph dies at once, no per-node teardown).
- **`Graph::Context`**: `set_needs_update`, `set_deadline`, `call_update`, `thread_is_updating`: the host-visible protocol (the host sets a
  deadline, the graph says it needs an update).
- **UIKitCore** contains `_UIUpdateSequence.mm` and `_UIUpdateCycleIdleScheduler.m` among its sources (string table): the update-cycle
  machinery is a real, separately named subsystem (to be read next).
- Design lessons already supported by names alone, for TerminalUI: (a) **dirty flags live on a tree of groups, not just on nodes**, so whole
  subtrees can be skipped or killed cheaply; (b) values are compared on edges to **cut propagation**; (c) disappearing views free a subgraph in
  bulk (arena reset); (d) a **built-in profiler and trace recorder** is part of the core, not an afterthought; TerminalUI should have one from day 1
  (signposts + a recorded "why did this node update" chain, the SwiftUI instrument's most useful feature).

### Study plan (each output is a note in `research/topics/` plus a probe or benchmark that could prove the note wrong)
| # | Question | Target | Method |
|---|---|---|---|
| R1 | What is a node (size/layout), how are inputs/outputs stored (inline small arrays? edge flags?), how does `update_attribute` recurse and detect cycles | `AttributeGraph` | disassemble `update_attribute`, `propagate_dirty`, `add_input`; lldb breakpoints on a tiny SwiftUI app of our own; cross-read OpenAttributeGraph (compare to the real one: do not assume it matches) |
| R2 | The view update turn: what runs, in which order, on what trigger (`ViewGraph`, `ViewRendererHost`, `Update.begin/end`, `UpdateScheduler`) | `SwiftUICore` | symbols + disassembly + signposts from the SwiftUI instrument on a probe app |
| R3 | `_makeView`/`_makeViewList`, identity (`ViewIdentity`, `_Tag`, `.id`), `DynamicContainer` and how `ForEach`/`if` create/destroy subgraphs | `SwiftUICore` | symbols; behavioural probes (state survives/doesn't survive) |
| R4 | `StackLayout` exact algorithm incl. rounding, spacing projection, `LayoutComputer`, caching, when a child is asked more than once | `SwiftUICore` | probes that count `sizeThatFits` calls with a custom `Layout` (observable from public API: no RE needed for the counts) |
| R5 | Environment/`PropertyList` (a persistent, hashed linked structure), preferences (`PreferenceKey` reduction order, `PreferenceNode`s) | `SwiftUICore` | symbols + probes |
| R6 | Lazy containers (`LazyVStack` windowing/prefetch), scroll view geometry, `onScrollGeometryChange` | `SwiftUI` | probes |
| R7 | `UIUpdateSequence`, `setNeedsLayout`/`updateProperties` coalescing, run-loop observer order, observation tracking registration | `UIKitCore` | ObjC metadata (`dyld_info -objc`), `strings`, lldb on a Catalyst sample |
| R8 | Hit testing, responder chain, gesture recognizer arbitration (`UIGestureEnvironment`), focus engine (`_UIFocusEngine`) | `UIKitCore` | metadata + probes |
| R9 | Compositing: `CA::Transaction` commit, `CA::Layer` dirty rects, damage tracking, tiling | `QuartzCore` | symbols; relevant to our GPU renderer's damage model |
| R10 | Text: `CTTypesetter`, `CTLine`, glyph caching, how fallback and `CTFontDescriptor` matching work, subpixel positioning, font smoothing | `CoreText`, `CoreGraphics` | symbols + probes; compare with FreeType/HarfBuzz behaviour in kitty |

Rules: findings are written as *claim → probe → verdict* (white paper §0); no code is transcribed, only algorithms described in our words
and re-derived; extracted binaries stay out of every repo; the extraction script and notes are what we keep.

## D. Dependency map: what the family already gives us, and the gaps to promote (or build)
Read from READMEs and `Package.swift` only; capabilities not re-verified in code.

| Need | Already in our tooling | Gap (to build or promote) |
|---|---|---|
| UTF-8 kernels, scans, base64, checksums | `AemiKernels`, `CAemiKernels`, `AemiKernel` | SIMD run scanner for the VT parser (printable-ASCII runs) → extend `AemiKernels` |
| Unicode tables, case folding, NFD | `AemiUnicode` | grapheme segmentation + East-Asian width + emoji presentation (TerminalKit has its own width tables, ADR-0024) → **promote to AemiUnicode**; UAX #9 bidi, UAX #14 line breaking (TerminalKitText has wrapping) |
| Text/rope/lines | `AemiText`, `AemiLexers`, `AemiDiff` | none for now |
| Markdown, HTML, Mermaid, JSON, regex, YAML/TOML, protobuf | `AemiMarkdown`, `AemiHTML`, `AemiMermaid`, `AemiJSON`, `AemiRegex`, `AemiHMMML`, `AemiProtobuf` | none: config, themes, IPC (protobuf for inter-process control API) are available |
| Process/files/IO | `AemiProcess` (process *table*), `AemiIO`, `AemiFileSystem`, `AemiRuntime` (offload pool, clocks) | **PTY + spawn** (not in any of them; `openpty`+`posix_spawn(SETSID)` probed) → new `AemiPTY` or inside the terminal core; decide when 2nd consumer appears (ask could use it for interactive tools) |
| Concurrency/test | `AemiTestKit`, `AemiTesting`, `AemiMetrics`, `Loggable`, `InternedStrings`/`AemiInterner` | none |
| Compression | none seen | **inflate/deflate (zlib) + PNG decode** for kitty graphics (`o=z`, `f=100`), later JPEG/WebP/AVIF if wanted; hashing/crypto: `AemiDigest`, `AemiArgon2` | → `AemiCompression` / `AemiImage` (promote: Atelier/ask also benefit) |
| Color | none seen (TerminalKit has `ColorRGB`, `OSCPalette`) | **color science**: sRGB/Display-P3/linear conversions, OKLab/OKLCH, gamut mapping, contrast (WCAG 2/APCA), ICC-lite → `AemiColor` (promote; ask's theme work "highly critical" in ask-wishes needs it too) |
| Fonts/typography | none | **OpenType/TrueType/CFF parsing, `cmap`, `glyf`/CFF outlines, GSUB/GPOS shaping, variable fonts (fvar/gvar/avar/HVAR), COLR/CPAL, sbix/CBDT emoji, font fallback/matching**. macOS can lean on CoreText for shaping/rasterising initially; **Linux requires our own** (no HarfBuzz/FreeType under the "own tooling" rule). Multi-month, high value: → `AemiFont` + `AemiShape`; also benefits Atelier, Mermaid layout (text metrics) |
| Rasterization | `AemiMermaid` draws scenes (own layout/draw) | glyph rasterizer (outline → coverage, analytic AA / signed distance), with GPU path; shared with Mermaid |
| GPU | `AemiSDR` (SwiftUI+Metal blurs; not a general layer) | **thin GPU layer**: Metal backend (macOS) and Vulkan backend (Linux), one shader source strategy (see E) → `AemiGPU` |
| Windowing/input on Linux | none | Wayland + X11 clients (own protocol code is feasible: Wayland is a documented wire protocol; X11 too) → `AemiWayland`/`AemiX11` (late, behind a window-system seam) |
| IPC/control | `AemiProtobuf`, `HTTP` | remote-control protocol for the terminal (kitty's `@` rc-protocol equivalent): protobuf over a unix socket |

## E. Terminal design consequences of the new requirements (all [unverified] designs)
**Color accuracy.** Treat color as a pipeline, not a hex string: cell colors arrive as sRGB/256/palette (+ kitty wide-gamut, docs/wide-gamut-colors.rst
exists in the kitty tree) → resolved in a *working space* → blended in **linear light** for text/alpha → converted to the display's space
(Display P3 / sRGB, EDR later). Text anti-aliasing needs gamma/contrast-aware blending (kitty and macOS font smoothing both do things here; to be
measured, the principles are known). Minimum-contrast enforcement, theme following system appearance (TerminalKit already observes it:
`SystemAppearance`), per-cell color tests against reference conversions (not eyeballed).
**GPU acceleration.** Glyph atlas + instanced cell quads as kitty/Ghostty do (kitty's `cell.slang`, `graphics.slang`, `border.slang` read as
file names); damage-aware presenting; `CAMetalLayer` on macOS (display-link paced, ProMotion aware), Vulkan on Linux. Shader strategy is the one
real fork: (i) write MSL and GLSL/SPIR-V by hand (two small sets, ~10 shaders), (ii) a build-time cross compiler (kitty uses Slang). Recommend (i):
no build dependency, and the set is small. A CPU renderer stays as the reference/test backend and the fallback on GPU loss (device-lost recovery is a
resilience requirement).
**Typography.** Ligatures, fallback chains, emoji (color), variable fonts, bold/italic synthesis rules, underline styles (curly/dotted: kitty
docs/underlines.rst), box-drawing/powerline glyphs drawn procedurally (pixel-exact, as kitty's `decorations.h` does), subpixel positioning inside the
cell grid, **kitty text sizing protocol (OSC 66)** with multicell cells, correct width/grapheme handling (our tables + AemiUnicode), bidi per
row. This is why a real font stack is in scope even on macOS if we want a consistent result across OSes.
**Graphics.** Full kitty graphics protocol: transmission modes (direct, file `t=f`/`t=t`, **shared memory `t=s`**), PNG/RGB/RGBA, zlib, chunking, placements with z-index,
**Unicode placeholders** (SwiftTerm already has `KittyPlaceholder`; read as file name), animation frames, delete/query, storage quotas. Plus Sixel and iTerm2
inline images for compatibility.
**Security** (a design input, not a feature): parser is memory-safe Swift with `StrictMemorySafety`, fuzzed, bounded memory per sequence and per
image; graphics `t=f`/`t=t` file reads gated by path policy and permission (kitty also restricts); OSC 52 read/write policy (prompting by default for reads);
paste protection, title/escape injection filtering, OSC 8 URL scheme allow-list, no raw-escape echo of untrusted data; child processes run with a clean
environment and resource limits where the OS allows; keystroke injection from the control socket authenticated (peer credentials). Sandboxing of
the app on macOS: hardened runtime, no unneeded entitlements.
**Resilience/reliability.** The parser cannot fail (invalid input → defined behaviour, tested exhaustively with a state-machine model and fuzzing);
bounded scrollback and image memory; a stuck renderer cannot block the PTY reader (separate threads, backpressure, a watchdog); deterministic
record/replay of a session's bytes for bug reports; differential fuzzing against kitty/Ghostty/WezTerm **running as external processes**.
**Linux.** Core (parser, screen, PTY via `openpty`/`posix_spawn`) must compile with no Darwin in it; the renderer and windowing sit behind seams
(TerminalKit roadmap 0024 already lists the Darwin-only parts of TerminalKit to fix first: `TerminalConnection`, `SignalHandler`/kqueue, `SystemAppearance`, clipboard).

## F. Revised roadmap: workstreams (estimates are guesses, unmeasured)
| WS | Scope | First gate | Rough months |
|---|---|---|---|
| WS0 Foundations | Promote to Aemi: grapheme/width/bidi (AemiUnicode), `AemiColor`, `AemiCompression`+`AemiImage` (PNG), PTY; fix TerminalKit Linux seams | each promoted target compiles on macOS+Linux, has benchmarks per white paper | 2–3 |
| WS1 Reverse engineering | R1–R10 notes, probes, with the extraction script kept | R1+R2+R7 notes before TerminalUI's core is frozen | continuous, 3 |
| WS2 TerminalUI | node arena, 3-phase update, layout, damage, input/focus, profiler/trace, harness; then ask migration (status line → questions → pickers → editor → transcript) | beats the current composer on the 3 hot scenarios (§4.5) before any ask surface moves | 6–8 |
| WS3 Terminal core (headless) | VT parser, screen/scrollback, reflow, modes/replies, PTY host, orchestration API, conformance suites, oracles | vttest/esctest pass list + differential fuzz vs oracles; replaces pyte in ask probes | 4–6 |
| WS4 Fonts + rasterizer | OpenType parser/shaper/rasterizer; CoreText backend first on macOS for parity checks | glyph-level conformance vs CoreText (macOS) and vs FreeType/HarfBuzz outputs (as external oracles) | 6–8, overlaps |
| WS5 Renderer + app (macOS) | Metal renderer, atlas, color pipeline, damage, window/tabs/splits, IME | latency and idle-wakeup measurements; color accuracy tests | 4–6 after WS3 |
| WS6 Graphics & protocols | kitty graphics (all modes, animation, placeholders), text sizing, Sixel/iTerm2, notifications, rc-protocol | kitty's own graphics tests + our oracle diffs | 3–4 |
| WS7 Linux | Vulkan backend, Wayland/X11, own font stack in production | same suites run on Linux CI | 4–6 |
Order that I'd follow: **WS0 + WS1 start now; WS3 headless core and WS2 in parallel; WS4 starts when WS3's cell model is fixed; WS5 when WS3+WS4 meet.**

## G. What I verified this round, and what remains open
Verified: the shared-cache extraction path and the toolset above; AttributeGraph/UIKitCore/SwiftUICore are present and symbol-readable; `chriseidhof/TerminalUI`
exists; aemi family package list and one-line descriptions (READMEs, not code). Not verified: every behavioural claim in C ("first findings") beyond what
a symbol name implies; which Aemi targets already contain grapheme-width/bidi/PNG/zlib code (I only read target names, not sources); that Vulkan-only is enough
on Linux GPUs and VMs (a GL fallback may be necessary); the month estimates.

Open decisions: (1) terminal name; (2) is Apple/swiftlang package usage acceptable *where aemi already pins it*; (3) platform libraries allowed (Vulkan loader, fontconfig discovery, libc) as "not dependencies"; (4) a decompiler (Ghidra/Hopper) for R1, R2, R7: install, or `llvm-objdump` + `lldb` only; (5) hand-written MSL+GLSL vs a cross-compiler.
