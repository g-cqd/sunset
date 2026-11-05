# Competitor benchmarks (roadmap 0014)

Runs [vtebench](https://github.com/alacritty/vtebench) (Alacritty's tool; each benchmark writes at least 1 MiB of escape-sequence output to the terminal and times how long the terminal takes to consume it) inside each terminal with the same grid (120×40), font (JetBrains Mono 14) and no user config.

```sh
cargo build --release --locked          # in a clone of alacritty/vtebench, default path /tmp/ref/vtebench (VTEBENCH=...)
bench/compete.sh <kitty|kitty-tuned|ghostty|wezterm|alacritty> [outdir] [max-secs] [max-samples]
bench/summarize.py [outdir]             # median and p90 per benchmark, milliseconds, lower is better
```

A window appears on the desktop for each run (about 20 s). Terminals tested: kitty 0.49.2, Ghostty 1.4.0, WezTerm 20240203 (stale), Alacritty 0.18.0-dev built from source. `kitty-tuned` adds `input_delay=0 repaint_delay=2 sync_to_monitor=no` (the settings kitty's docs give for low latency).

**Read `results/*/summary.txt` with its caveats:** the first pass was taken at load average 7–17 from other work on the machine, with 10 samples per benchmark, one run, windows visible, vsync behaviour not controlled, and "the time to consume output" is not
frame rate or latency. It is a baseline to beat, not a ranking to publish. Repeat on a quiet machine, several runs, before using any number in a claim.

## Contention and reproducibility (ADR-0017)

```sh
clang -O2 bench/hog.c -o /tmp/hog                      # controlled background load (threads, seconds, qos, mix)
bench/repro.sh 10 8 spin interactive -- env QUICK=1 /tmp/probe/vtmodel/v2   # N launches ambient vs under the hog; median, min, max, cv per metric
```
`stats.py` summarises `name=value` lines. The probe in QUICK mode emits wall p50/p90, instructions retired and cycles per MiB (from `proc_pid_rusage`).
Result in one line: wall times under any load drift between sessions (compare interleaved only); instructions retired did not move (0.0 % cv) and are the gate.
