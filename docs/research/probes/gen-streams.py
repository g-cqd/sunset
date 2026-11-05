#!/usr/bin/env python3
"""Generates headless byte streams equivalent to vtebench's benchmarks (needs a clone of alacritty/vtebench at /tmp/ref/vtebench). Output: /tmp/probe/vtstreams/*.bin
(vtebench's own scripts read the tty size, so they cannot run headless; these follow the scripts' printf loops at 120x40.)"""
import os
B = "/tmp/ref/vtebench/benchmarks"; cols, lines = 120, 40
os.makedirs("/tmp/probe/vtstreams", exist_ok=True)
def w(name, data): open(f"/tmp/probe/vtstreams/{name}.bin", "wb").write(data); print(name, len(data))
w("scrolling", b"y\n" * 524288)
fs = b"".join((chr(65 + i % 26) * cols).encode() + b"\n" for i in range(26)); w("scrolling_fullscreen", fs * (1048576 // len(fs) + 1))
w("scrolling_top_region", b"\x1b[?1049h\x1b[2;40r" + b"y\n" * 524288)
out = bytearray(); offset = 0
while len(out) < 1048576:
    for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        out += b"\x1b[H"
        for l in range(1, lines + 1):
            for c in range(1, cols + 1):
                idx = l + c + offset; out += f"\x1b[38;5;{idx % 156 + 100};48;5;{255 - idx % 156 + 100};1;3;4m{ch}".encode()
        offset += 1
        if len(out) >= 1048576: break
w("dense_cells", bytes(out))
vs = open(f"{B}/sync_medium_cells/vim_session", "rb").read(); w("medium_cells", vs * (1048576 // len(vs) + 1))
sy = open(f"{B}/unicode/symbols", "rb").read(); w("unicode", sy * (1048576 // len(sy) + 1))
