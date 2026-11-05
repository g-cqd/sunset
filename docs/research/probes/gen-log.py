#!/usr/bin/env python3
"""Builds /tmp/probe/vtstreams/log.bin: ~8.5 MiB of coloured log lines from real text (needs /tmp/probe/vtscan/corpus.txt = cat of ask/Sources/AskTUI/*.swift)."""
import random
random.seed(3)
lines = open("/tmp/probe/vtscan/corpus.txt", "rb").read().split(b"\n")
cols = [b"\x1b[32m", b"\x1b[31m", b"\x1b[33m", b"\x1b[36m", b"\x1b[1;34m", b"\x1b[38;5;208m", b"\x1b[38;2;120;200;80m"]
out = bytearray()
while len(out) < 8 * 1048576:
    for l in lines:
        l = l[:110]
        if random.random() < 0.5: out += random.choice(cols) + b"[" + random.choice([b"INFO", b"WARN", b"OK", b"DEBUG"]) + b"]\x1b[0m "
        out += l + b"\r\n"
open("/tmp/probe/vtstreams/log.bin", "wb").write(bytes(out)); print(len(out))
