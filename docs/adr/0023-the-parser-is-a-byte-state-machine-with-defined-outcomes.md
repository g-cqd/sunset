---
status: accepted
date: 2026-11-05
---

# 0023 — The parser is a byte state machine into a sink, with a defined outcome for every input

## Context

Roadmap 0003 starts the core. Terminals differ on edge cases (C1 controls, overlong or invalid UTF-8, over-long sequences, how strings end), and an untrusted program chooses the bytes (white paper §9). The parser has to be allocation-free, resumable at any byte, and specialised with its consumer (ADR-0020).

## Decision

`VTParser` (SunsetCore, `Sources/SunsetCore/Parser`) is the DEC ANSI-compatible state machine of vt100.net as xterm extends it, over `Span<UInt8>`, reporting into a generic `VTSink` (the screen will be a sink in the same module, so it is specialised; `ParseCounter` is the concrete front for other modules).

- **Resumable**: all state is in the parser; input may be cut anywhere, inside UTF-8 or an escape sequence. Tested: random streams, random cuts and byte-by-byte give the same events as the whole.
- **UTF-8 only**; invalid input gives U+FFFD per maximal invalid subpart (WHATWG), overlongs, surrogates and above U+10FFFF included.
- **C1 controls count only as UTF-8 scalars** (U+0080...U+009F), act as their ESC forms (xterm in UTF-8 mode) and reach the sink as `execute(0x80...0x9F)` when they are not introducers. A non-ASCII byte inside an escape or control sequence abandons the sequence and is read afresh.
- **Bounds, no truncation**: at most 32 parameters (values saturate at 65535; `:` sub-parameters are flagged), at most 2 intermediates, one private marker (`<=>?`) only first. A sequence that breaks a bound or puts a parameter after an intermediate is ignored whole, up to its final byte; nothing partial is ever reported.
- **Strings** (OSC, DCS, APC, PM, SOS) end at ST (ESC \ or U+009C), at BEL for OSC only, or at an ESC that starts another sequence; CAN and SUB cancel. Content passes to the sink as it arrives, in pieces, up to `maxStringLength` (default 1 MiB); the rest is dropped and the string ends with `completed: false`. An invalid DCS header swallows its string silently.
- C0 controls inside a control sequence are executed and the sequence goes on; ESC restarts; DEL is ignored.
- Printable ASCII is delivered as runs (`printASCII(Span)`), the hook for the vector fast path of probe T0.4; non-ASCII as scalars.

## Evidence (`Tests/SunsetCoreTests`, 24 tests; `Benchmarks/Benchmarks/ParserBenchmarks`, `bench/results/2026-11-05/parser-baseline.txt`)

- Red first: the tests were written against an empty parser and failed (23 of 24 issues; the ones passing did so by absence); the implementation then made all pass.
- Property tests (3000 random streams each): split invariance, balanced strings, no sequence inside a string, string content never over the limit, printable round-trip through any cut. Sabotage: resetting the C2-hold per call was caught by the split test; not resetting the truncation flag was *not* caught by the properties (they compare the parser with itself) and needed a directed test, now added.
- Instructions per 1 MiB, p50, release, one machine: ASCII text 11 M (about 10 per byte), UTF-8-heavy text 44 M, OSC titles 21 M, cursor moves (`CSI r;c H`, ~11 bytes each) 81 M, truecolor SGR 87 M. **0 mallocs** on all five. Wall clock (reported, not gated): 0.8 ms (ASCII) to 11 ms (CSI-dense) per MiB.

## Not established

- The CSI cost (~70-80 instructions per byte, ~800 per sequence) is unexamined; the likely suspects are the per-byte state dispatch and the 64-byte parameter block copied into the sink. No comparison with the oracles' parsers yet (roadmap 0014 / 0005).
- No `esctest`/`vttest` fixtures yet, no fuzzing beyond the random streams above, no SIMD path (T0.4 variants unmeasured here), and the parser is not yet connected to a screen.
- The C1 and over-length policies are my choice from xterm's behaviour, not checked against the oracles run as processes (ADR-0004).
