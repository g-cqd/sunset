#!/usr/bin/env python3
"""Summarises vtebench .dat files (one column per benchmark, one row per sample, milliseconds): median and p90 per terminal.
Usage: bench/summarize.py [outdir] (default /tmp/sunset-bench). Lower is better. The load average at run time is in <terminal>.env."""
import sys, glob, os, statistics as st
out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/sunset-bench"
data = {}
for f in sorted(glob.glob(os.path.join(out, "*.dat"))):
    t = os.path.basename(f)[:-4]
    rows = [l.split() for l in open(f).read().strip().splitlines()]
    names, vals = rows[0], rows[1:]
    data[t] = {n: [float(r[i]) for r in vals if i < len(r) and r[i] != '_'] for i, n in enumerate(names)}
bench = sorted({n for d in data.values() for n in d})
terms = list(data)
def pct(xs, p): xs = sorted(xs); return xs[min(len(xs) - 1, int(round(p * (len(xs) - 1))))]
print("median ms (p90 ms) per sample; samples n; lower is better\n")
print(f"{'benchmark':32}" + "".join(f"{t:>22}" for t in terms))
for b in bench:
    row = f"{b:32}"
    for t in terms:
        xs = data[t].get(b)
        row += f"{(f'{st.median(xs):.0f} ({pct(xs, .9):.0f}) n={len(xs)}' if xs else '-'):>22}"
    print(row)
