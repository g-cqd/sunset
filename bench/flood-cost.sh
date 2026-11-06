#!/bin/bash
# What a terminal costs to print N lines: instructions, cycles and CPU time of its process for the whole flood, and the time the flood took.
# Usage: bench/flood-cost.sh <kitty|ghostty|wezterm|alacritty|sunset> [lines=1000000]   (one window appears; ~20 s)
# The same program in every terminal ("yes ... | head -n N"), 120x40, JetBrains Mono 14, default config. Counters do not depend on machine load the way wall time does.
set -euo pipefail
T="$1"; N="${2:-1000000}"
HERE="$(cd "$(dirname "$0")" && pwd)"; BIN=/tmp/rusage_total; [ -x "$BIN" ] || clang -O2 "$HERE/rusage_total.c" -o "$BIN"
MARK="sunset-flood-$T-$$"; FONT="JetBrains Mono"; SIZE=14; COLS=120; ROWS=40; DONE="/tmp/$MARK.done"; GO="/tmp/$MARK.go"; rm -f "$DONE" "$GO"
LINE='the quick brown fox jumps over the lazy dog 0123456789 abcdefghij'
CMD="while [ ! -f $GO ]; do sleep 0.1; done; s=\$(date +%s.%N); yes '$LINE' | head -n $N; e=\$(date +%s.%N); echo \"\$s \$e\" > $DONE; sleep 30 # $MARK"
case "$T" in
  kitty)     /Applications/kitty.app/Contents/MacOS/kitty --config NONE -o scrollback_lines=100000 -o font_family="$FONT" -o font_size=$SIZE -o remember_window_size=no -o initial_window_width=${COLS}c -o initial_window_height=${ROWS}c -o confirm_os_window_close=0 sh -c "$CMD" >/dev/null 2>&1 & ;;
  ghostty)   open -na /Applications/Ghostty.app --args --config-default-files=false --scrollback-limit=100000000 --font-family="$FONT" --font-size=$SIZE --window-width=$COLS --window-height=$ROWS --confirm-close-surface=false --quit-after-last-window-closed=true -e sh -c "$CMD" >/dev/null 2>&1 ;;
  wezterm)   /Applications/WezTerm.app/Contents/MacOS/wezterm --config-file /dev/null --config "scrollback_lines=100000" --config "initial_cols=$COLS" --config "initial_rows=$ROWS" --config "font_size=$SIZE" --config "font=wezterm.font('$FONT')" start --always-new-process -- sh -c "$CMD" >/dev/null 2>&1 & ;;
  alacritty) /tmp/ref/alacritty/target/release/alacritty --config-file /dev/null -o "scrolling.history=100000" -o "window.dimensions.columns=$COLS" -o "window.dimensions.lines=$ROWS" -o "font.size=$SIZE" -o "font.normal.family=\"$FONT\"" -e sh -c "$CMD" >/dev/null 2>&1 & ;;
  sunset)    "${SUNSET_BIN:-$HERE/../.build/release/sunset-app}" --font "$FONT" --size $SIZE --scrollback 100000 -- sh -c "$CMD" >/dev/null 2>&1 & ;;
  *) echo "unknown terminal"; exit 2 ;;
esac
PID=""
for _ in $(seq 1 60); do
  for p in $(pgrep -f "$MARK" || true); do
    c=$(basename "$(ps -o comm= -p "$p" 2>/dev/null)" 2>/dev/null || true)
    case "$c" in *"$T"*|*sunset-render*|*sunset-app*) PID=$p; break ;; esac
  done
  [ -n "$PID" ] && break; sleep 0.5
done
[ -n "$PID" ] || { echo "$T: terminal process not found"; exit 1; }
sleep 4
BEFORE=$("$BIN" "$PID"); touch "$GO"
for _ in $(seq 1 1200); do [ -f "$DONE" ] && break; sleep 0.25; done
[ -f "$DONE" ] || echo "(flood never finished)"
sleep 3   # the terminal may still be drawing the tail
AFTER=$("$BIN" "$PID")
read -r s e < "$DONE" || true
python3 - "$T" "$N" "$BEFORE" "$AFTER" "${s:-0}" "${e:-0}" <<'PY'
import sys
t,n,b,a,s,e=sys.argv[1],int(sys.argv[2]),sys.argv[3].split(),sys.argv[4].split(),float(sys.argv[5]),float(sys.argv[6])
d=lambda i: float(a[i])-float(b[i])
print(f"{t:10s} lines={n} flood_wall={e-s:6.2f}s  Ginstr={d(0)/1e9:7.2f}  Gcycles={d(1)/1e9:7.2f}  cpu={d(2)/1000:6.2f}s  peak_footprint={a[3]}MB")
PY
rm -f "$DONE" "$GO"; pkill -f "$MARK" 2>/dev/null || true; kill "$PID" 2>/dev/null || true; sleep 1
