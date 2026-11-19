---
status: accepted
date: 2026-11-19
---

# 0087 — The code's shape: bodies on lines of their own, tasks and time injected, layers by concern

## Context

The owner's note n55 (2026-11-19), and the counts in roadmap 0086: 694 one-line bodies, 125 raw tasks and sleeps, 56 direct
reads of the time, 215 clones, a 262-file module holding both a model and its views.

## Decision

1. **Bodies span lines.** A `func`, `init`, `subscript`, computed `var` or accessor never has its body on its signature's line:
   ```swift
   var isEmpty: Bool {
       items.isEmpty
   }
   ```
   `SourceShapeTests` fails the suite on any (the repository's own gate, beside `SourceStructureTests`: the synced
   `.swiftlint.yml` stays metrics only, as the family keeps it); `Scripts/tools/expand-one-line-bodies.py` spans them;
   `respectsExistingLineBreaks` stays, so what is spanned stays spanned. Protocol requirements (`{ get }`) are not bodies;
   a stored property's observers are.
2. **Tasks are spawned through a `TaskProvider`** (AemiRuntime), injected, `LiveTaskProvider()` by default; a test passes a
   `TaskProviderSpy` and waits for the tasks it started. Long-lived loops are `role: .observation`.
3. **Time is a `Clock`.** Every sleep is `clock.sleep(for:)` on an injected `any Clock<Duration>` (`ContinuousClock()` by
   default, `TestClock` in tests); every "now" is read from the clock or from an injected provider (`LiveClock` for wall time).
4. **Layers by concern.** A model module imports neither SwiftUI nor AppKit; views live beside it in a module of their own; the
   app target only wires modules together. One owner per decision (ADR-0086).
5. **No new clone.** dolly runs with a baseline that only shrinks.

## Consequences

- The tree is reformatted once (stage A); history shows it as one commit of its own.
- The banned list grows by the raw forms of rules 2 and 3, with a count that may only go down until it is zero.
- The rule is a test of this repository; the family may take `SourceShape` and the script, or not (the owner's call there).
