#!/usr/bin/env python3
"""Reads lines like 'TAG name=value name=value' on stdin; prints n, median, min, max, max/min and coefficient of variation per name."""
import sys, re, statistics as st, collections
vals = collections.defaultdict(list)
for line in sys.stdin:
    for k, v in re.findall(r"(\w+)=([0-9.]+)", line): vals[k].append(float(v))
for k, xs in vals.items():
    m = st.median(xs); cv = (st.pstdev(xs) / st.mean(xs)) * 100 if len(xs) > 1 else 0
    print(f"  {k:14} n={len(xs):2} median={m:8.3f} min={min(xs):8.3f} max={max(xs):8.3f} max/min={max(xs)/min(xs):5.2f} cv={cv:5.1f}%")
