#!/usr/bin/env python3
"""Builds a terminal byte stream from local ask session files (private data: the stream stays in /tmp and only aggregate numbers leave the machine).
Rendering rules mimic ask in a terminal: user text '> ' in bold cyan, assistant text plain, tool output dim, fenced code yellow, CRLF line ends."""
import json, glob, os, sys, random
random.seed(1)
LIMIT = int(sys.argv[1]) if len(sys.argv) > 1 else 64 * 1048576
files = sorted(glob.glob(os.path.expanduser("~/.local/state/ask/sessions/**/*.jsonl"), recursive=True))
random.shuffle(files)
out = bytearray(); n_entries = 0
def emit(style, text):
    global out
    incode = False
    for line in text.replace("\r\n", "\n").split("\n"):
        if line.startswith("```"): incode = not incode
        st = style if not incode else "\x1b[33m"
        out += (st + line + "\x1b[0m\r\n").encode("utf-8", "replace")
def texts(o, key=("text", "output", "content")):
    if isinstance(o, str): return
    if isinstance(o, dict):
        for k, v in o.items():
            if k in key and isinstance(v, str) and len(v) > 0 and k != "signature": yield v
            elif k == "signature": continue
            else: yield from texts(v, key)
    elif isinstance(o, list):
        for v in o: yield from texts(v, key)
for f in files:
    try:
        for line in open(f, "r", encoding="utf-8", errors="replace"):
            try: e = json.loads(line)
            except Exception: continue
            p = e.get("payload")
            if not isinstance(p, dict): continue
            kind = p.get("kind", "")
            style = {"user": "\x1b[1;36m> ", "assistant": "", "tool": "\x1b[2m"}.get(kind, "\x1b[2m")
            for t in texts(p):
                if len(t) > 20000: t = t[:20000]
                emit(style, t); n_entries += 1
            if len(out) >= LIMIT: break
    except Exception: continue
    if len(out) >= LIMIT: break
open("/tmp/probe/corpus/sessions.bin", "wb").write(bytes(out)); print(len(out), "bytes from", n_entries, "text fields")
