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
