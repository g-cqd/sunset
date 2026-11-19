#!/bin/bash
# t59: the cost of WebKit's stores in an AES-256 encrypted sparse bundle (opened with a passphrase on stdin, not shown in
# Finder) against a plain folder on the same disk (FileVault on). Five runs each; release-agnostic (I/O only). 2026-11-19.
set -euo pipefail
root="${1:-.build/probes/sealed-image}"
rm -rf "$root"; mkdir -p "$root/plain"
pass="probe-$(uuidgen)"
t() { python3 -c 'import time; print(time.perf_counter())'; }
s=$(t); printf '%s' "$pass" | hdiutil create -quiet -size 2g -type SPARSEBUNDLE -fs APFS -volname probe -encryption AES-256 -stdinpass "$root/img.sparsebundle"; e=$(t)
echo "create: $(python3 -c "print(round(($e-$s)*1000))") ms"
for i in 1 2 3 4 5; do
  s=$(t); printf '%s' "$pass" | hdiutil attach -quiet -nobrowse -owners on -mountpoint "$root/mnt" -stdinpass "$root/img.sparsebundle"; e=$(t)
  a=$(python3 -c "print(round(($e-$s)*1000))")
  s=$(t); hdiutil detach -quiet "$root/mnt"; e=$(t)
  echo "attach $i: $a ms, detach: $(python3 -c "print(round(($e-$s)*1000))") ms"
done
printf '%s' "$pass" | hdiutil attach -quiet -nobrowse -owners on -mountpoint "$root/mnt" -stdinpass "$root/img.sparsebundle"
python3 - "$root/plain" "$root/mnt" <<'PY'
import os, sqlite3, sys, time, statistics
def sqlite_run(d):
    p = os.path.join(d, "bench.sqlite")
    for f in (p, p + "-wal", p + "-shm"):
        if os.path.exists(f): os.remove(f)
    c = sqlite3.connect(p); c.execute("PRAGMA journal_mode=WAL"); c.execute("PRAGMA synchronous=NORMAL")
    c.execute("CREATE TABLE r(k BLOB PRIMARY KEY, v BLOB)")
    blob = os.urandom(600); t0 = time.perf_counter()
    for i in range(2000):  # 2000 small transactions, like visits and cookie updates
        c.execute("INSERT INTO r VALUES (?, ?)", (os.urandom(16), blob)); c.commit()
    c.close(); return (time.perf_counter() - t0) * 1000
def files_run(d):
    sub = os.path.join(d, "cache"); os.makedirs(sub, exist_ok=True)
    for f in os.listdir(sub): os.remove(os.path.join(sub, f))
    data = os.urandom(24 * 1024); t0 = time.perf_counter()
    for i in range(2000):  # a network cache's shape: 2000 files of 24 KiB, each written then fsync'd
        with open(os.path.join(sub, f"{i:05}"), "wb") as fh: fh.write(data); fh.flush(); os.fsync(fh.fileno())
    w = (time.perf_counter() - t0) * 1000; t0 = time.perf_counter()
    for i in range(2000):
        with open(os.path.join(sub, f"{i:05}"), "rb") as fh: fh.read()
    return w, (time.perf_counter() - t0) * 1000
for label, d in (("plain", sys.argv[1]), ("image", sys.argv[2])):
    s = [sqlite_run(d) for _ in range(5)]; f = [files_run(d) for _ in range(5)]
    q = lambda xs: f"p50 {statistics.median(xs):.0f} ms, min {min(xs):.0f}, max {max(xs):.0f}"
    print(f"{label}: sqlite 2000 commits {q(s)} | files write+fsync {q([x[0] for x in f])} | read {q([x[1] for x in f])}")
PY
hdiutil detach -quiet "$root/mnt"
du -sh "$root/img.sparsebundle"
rm -rf "$root"
