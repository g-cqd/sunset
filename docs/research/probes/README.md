# Probes (throwaway C, not shipped code)

Each is one file, built with `clang -Os` (Aemi ships its C at `-Os`, aemi ADR-0011) on arm64, outputs consumed so they cannot be optimised away. Results are in `../kernels-study.md` and the diary.

```sh
A=<path to aemi>/Sources
clang -Os -std=c11 -I$A/CAemiKernels/include -I$A/CAemiCPU/include $A/CAemiKernels/adf_*.c $A/CAemiCPU/adf_cpu_features.c vtscan.c -o vtscan && ./vtscan
clang -Os -std=c11 cells.c -o cells && ./cells
clang -Os lz.c -o lz -lcompression && ./lz <any text file>
```

Lessons already paid for (do not repeat): a pure function called in a loop with unchanged arguments is hoisted, and the first run of `cells.c` (b) "measured" 14 ns for every variant for that reason; calls now go through a
`volatile` function pointer with a memory clobber (the same class of flaw aemi ADR-0011 records). Machine: Apple M3 (`machdep.cpu.brand_string`), macOS 27.0.1, load not controlled.

## Swift VT model (T0.4)

```sh
python3 gen-streams.py && mkdir -p /tmp/probe/vtmodel && cp vtmodel.swift /tmp/probe/vtmodel/main.swift && cd /tmp/probe/vtmodel && swiftc -O -wmo main.swift -o vtmodel && ./vtmodel
```
A headless subset of a terminal (print, UTF-8, LF/CR/BS/HT, cursor moves, ED/EL, SGR with a style table, DECSTBM) with 8-byte cells and row indirection. It uses unsafe pointers throughout (a probe; the real code must justify each `unsafe`, white paper). It has no scrollback, grapheme data, hyperlinks, paged styles, reflow, PTY or renderer, so its numbers are a **floor**, not a prediction.

### vtmodel2.swift (T0.1 and T0.4b): cell width, scrollback ring, cold encoder

```sh
python3 gen-streams.py   # also needs /tmp/probe/vtstreams/log.bin: 8 MiB of coloured log lines built from ask's Swift sources (see diary 2026-11-05-01)
swiftc -O -wmo vtmodel2.swift -o vtmodel2 && ./vtmodel2
```
**Correction (stream generator):** the first version of `gen-streams.py` wrote bare `\n` for the scrolling streams. A real tty turns `\n` into `\r\n` (ONLCR) before the terminal sees it, so my first `vtmodel` numbers ran a staircase workload. The generator now writes `\r\n`; `vtmodel.swift` results quoted before this correction are superseded by `vtmodel2.swift`'s column C8 (same state machine).
**Noise:** the machine ran at load average 9–14 from other work during most runs; absolute numbers moved by up to 2× between runs (scrolling C8: 5.2 in the one quiet window, 10.3–14.3 under load). Ratios between cell types held. Quiet-machine reruns are tracked.
