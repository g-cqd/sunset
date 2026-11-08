#!/bin/bash
# Footprint and cost of the app with the CPU or the GPU renderer: a flood of output, then idle (owner: the GPU renderer was never measured).
# Usage: bench/renderer-ab.sh <binary> <cpu|gpu> [lines=1000000] [idle-seconds=10]
set -euo pipefail
BIN="${1:?binary}"; R="${2:?cpu|gpu}"; N="${3:-1000000}"; IDLE="${4:-10}"
HERE="$(cd "$(dirname "$0")" && pwd)"; S=/tmp/rusage_sample; [ -x "$S" ] || clang -O2 "$HERE/rusage_sample.c" -o "$S"
CONF=$(mktemp /tmp/renderer-ab.XXXXXX); printf '{ "renderer": "%s", "tabs": { "mode": "native" } }\n' "$R" > "$CONF"
DONE=/tmp/renderer-ab.$$.done; rm -f "$DONE"
(SUNSET_CONFIG="$CONF" SUNSET_SESSION=/dev/null "$BIN" -- sh -c "yes 'the quick brown fox jumps over the lazy dog 0123456789 abcdefghij' | head -n $N; touch $DONE; sleep 900" >/dev/null 2>&1 &)
sleep 3; PID=$(pgrep -f "^$BIN -- " | head -1); [ -n "$PID" ] || { echo "app not found"; exit 1; }
osascript -e 'tell application "System Events" to set frontmost of first process whose unix id is '"$PID"' to true'
START=$(python3 -c 'import time;print(time.time())')
for _ in $(seq 1 900); do [ -f "$DONE" ] && break; sleep 0.2; done
END=$(python3 -c 'import time;print(time.time())')
echo "$R: flood of $N lines took $(python3 -c "print(round($END-$START,2))") s wall, footprint $("$S" "$PID" 1 | cut -d' ' -f1,2)"
sleep 4; echo "$R: idle ${IDLE} s: $("$S" "$PID" "$IDLE")"
vmmap -summary "$PID" 2>/dev/null | grep -E "IOAccelerator|IOSurface|Metal" | head -4
kill "$PID" 2>/dev/null || true; rm -f "$CONF" "$DONE"
