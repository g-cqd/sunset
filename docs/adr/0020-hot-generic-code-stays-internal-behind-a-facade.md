---
status: accepted
date: 2026-11-05
---

# 0020 — Hot generic code stays internal behind a non-generic facade

## Context

The VT-model benchmarks (sunset `Benchmarks/`, ADR-0018) were first run with the generic model in the benchmark target, then moved into a library target so a second executable (the handoff probe) could share it. The instruction gate (ADR-0017/0019) moved at once, and the same code, line for line, cost very different amounts depending only on how it was exposed. The model is generic over its cell type (`Model<C: CellType>`), which is how the design compares 8, 16 and 32-byte cells; the framework (TerminalUI) will be generic in the same way.

## Probe (instructions retired per ~1 MiB pass, `swift package benchmark`, release, ordo-one/benchmark 1.38.0, identical source except for access control and call structure)

| Arrangement | scrolling / C8 | dense_cells / C8 |
|---|---|---|
| Model in the benchmark's own module (`internal`, specialised) | **109 M** | **92 M** |
| Model in a library module, `package` members, called generically from the consumer | 753 M (6.9×) | 109 M |
| same, plus `-cross-module-optimization` | 753 M | 109 M (the flag changed nothing) |
| `final class ScreenImpl<C>` facade, instantiated per cell type | 230 M (2.1×) | 101 M |
| three concrete facade classes (`Screen8/16/32`), Model `package` | 230 M | 101 M |
| three concrete facade classes, Model **`internal`** | **109 M** | **92 M** |

Reading, with what is and is not established:

- Generic code reached from another module is not specialised: 6.9× the instructions (the clearing of a row goes through a protocol witness per cell).
- A generic class's methods reached through its vtable are not specialised either (2.1× left after the first facade).
- `package`/`public` visibility alone, on a fully concrete facade, cost 2.1×: the compiler optimises an `internal` hot path (inlining, specialisation, dead-code removal) more aggressively than one other modules could call. The mechanism is my inference from the instruction counts, not a read of the compiler; the counts are the evidence.
- `-cross-module-optimization` did not recover any of it here.

## Decision

- The hot path (model, layout, draw, parse) is **`internal`**, generic over concrete types the module itself instantiates, and exposed to other modules only through **non-generic facades** (a concrete class or a function per configuration) that call it with concrete types. One virtual call per chunk or frame is the accepted price.
- Do not mark hot generic code `@inlinable`/`@usableFromInline` to leak it across modules unless a benchmark shows that cheaper than a facade.
- Every such boundary is covered by an instruction benchmark (ADR-0018), which is what caught this.

## Consequences

- Products are split by weight, not to share internals (white paper): a second consumer of a hot path means a facade for it, or the consumer goes in the same module.
- Test targets use `@testable`/explicit testability (white paper §4), which keeps `internal` hot code reachable.
