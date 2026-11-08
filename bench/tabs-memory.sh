#!/bin/bash
# Footprint of the app with several tabs that have each printed a flood of output (owner note n11).
# Usage: bench/tabs-memory.sh <binary> [tabs=4] [lines=300000] [settle-seconds=12] [file]
# With a file, each tab prints that file (cat) instead of a repeated line.
# Needs the app to be allowed to be driven through System Events (⌘T). Prints the footprint (physical, as Activity Monitor) after each tab and the split of it.
set -euo pipefail
BIN="${1:?binary}"; TABS="${2:-4}"; LINES_N="${3:-300000}"; SETTLE="${4:-12}"; FILE="${5:-}"
if [ -n "$FILE" ]; then PRINT="cat $FILE $FILE $FILE"; else PRINT="yes 'the quick brown fox jumps over the lazy dog 0123456789 abcdefghij' | head -n $LINES_N"; fi
HERE="$(cd "$(dirname "$0")" && pwd)"; SAMPLE=/tmp/rusage_sample; [ -x "$SAMPLE" ] || clang -O2 "$HERE/rusage_sample.c" -o "$SAMPLE"
CONF=$(mktemp /tmp/tabs-memory.XXXXXX); printf '%s\n' '{ "tabs": { "mode": "native" }, "sidebar": { "enabled": true, "autoHide": false } }' > "$CONF"
MARK="tabsmem-$$"
(SUNSET_CONFIG="$CONF" SUNSET_SESSION=/dev/null "$BIN" -- sh -c "$PRINT; sleep 900 # $MARK" >/dev/null 2>&1 &)
sleep 8; PID=$(pgrep -f "^$BIN -- " | head -1); [ -n "$PID" ] || { echo "app not found"; exit 1; }
osascript -e 'tell application "System Events" to set frontmost of first process whose unix id is '"$PID"' to true'; sleep 1
sleep "$SETTLE"; echo "1 tab:  $("$SAMPLE" "$PID" 2 | cut -d' ' -f1)"
for i in $(seq 2 "$TABS"); do
  osascript -e 'tell application "System Events" to keystroke "t" using command down'; sleep "$SETTLE"
  echo "$i tabs: $("$SAMPLE" "$PID" 2 | cut -d' ' -f1)"
done
footprint "$PID" 2>/dev/null | sed -n '/Dirty/,/^$/p' | head -8
kill "$PID" 2>/dev/null || true; rm -f "$CONF"
