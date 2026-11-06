#!/usr/bin/env python3
"""Side-by-side table of the replies each terminal gave to the queries stream (files kept by oracle-compare.sh in its temp directory).

Usage: Scripts/oracle-table.py DIR [name]      DIR is the directory oracle-compare.sh printed; name defaults to 18-queries.
"""
import re
import sys

directory = sys.argv[1]
name = sys.argv[2] if len(sys.argv) > 2 else "18-queries"
files = {"sunset": f"{name}.sunset.r", "kitty": f"{name}.kitty.replies", "ghostty": f"{name}.ghostty.replies", "alacritty": f"{name}.alacritty.replies"}


def load(path):
    replies = {}
    try:
        for line in open(f"{directory}/{path}"):
            key, _, value = line.partition(":")
            replies[key] = re.sub(r"\s+", " ", value).strip().replace("033 [", "").replace("033", "ESC") or "(none)"
    except FileNotFoundError:
        pass
    return replies


tables = {terminal: load(path) for terminal, path in files.items()}
keys = list(dict.fromkeys(key for table in tables.values() for key in table))
print(f"{'query':18}" + "".join(f"| {terminal:22}" for terminal in tables))
for key in keys:
    row = [tables[terminal].get(key, "-") for terminal in tables]
    flag = "" if len(set(row)) == 1 else "  <-- differs"
    print(f"{key:18}" + "".join(f"| {value[:21]:22}" for value in row) + flag)
