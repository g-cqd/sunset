#!/bin/bash
# Footprint and idle cost of a terminal: launches it with a command that prints N lines (or nothing) then sleeps, waits for it to settle, samples the terminal process.
# Usage: bench/idle.sh <kitty|ghostty|wezterm|alacritty|sunset> <lines> [settle-seconds] [sample-seconds]
# Scrollback is set to 100,000 lines where the terminal counts lines (ghostty counts bytes: 100,000,000). Cursor blink etc. are each terminal's default (said in the output).
set -euo pipefail
T="$1"; LINES_N="$2"; SETTLE="${3:-8}"; SAMPLE="${4:-10}"
HERE="$(cd "$(dirname "$0")" && pwd)"; BIN=/tmp/rusage_sample; [ -x "$BIN" ] || clang -O2 "$HERE/rusage_sample.c" -o "$BIN"
MARK="sunset-idle-$T-$$"; FONT="JetBrains Mono"; SIZE=14; COLS=120; ROWS=40
DONE="/tmp/$MARK.done"; rm -f "$DONE"
CMD="yes 'the quick brown fox jumps over the lazy dog 0123456789 abcdefghij' | head -n $LINES_N; touch $DONE; sleep $((SETTLE + SAMPLE + 12)) # $MARK"
case "$T" in
  kitty)     /Applications/kitty.app/Contents/MacOS/kitty --config NONE -o scrollback_lines=100000 -o font_family="$FONT" -o font_size=$SIZE -o remember_window_size=no -o initial_window_width=${COLS}c -o initial_window_height=${ROWS}c -o confirm_os_window_close=0 sh -c "$CMD" >/dev/null 2>&1 & ;;
  ghostty)   open -na /Applications/Ghostty.app --args --config-default-files=false --scrollback-limit=100000000 --font-family="$FONT" --font-size=$SIZE --window-width=$COLS --window-height=$ROWS --confirm-close-surface=false --quit-after-last-window-closed=true -e sh -c "$CMD" ;;
  wezterm)   /Applications/WezTerm.app/Contents/MacOS/wezterm --config-file /dev/null --config "scrollback_lines=100000" --config "initial_cols=$COLS" --config "initial_rows=$ROWS" --config "font_size=$SIZE" --config "font=wezterm.font('$FONT')" start --always-new-process -- sh -c "$CMD" >/dev/null 2>&1 & ;;
  alacritty) /tmp/ref/alacritty/target/release/alacritty --config-file /dev/null -o "scrolling.history=100000" -o "window.dimensions.columns=$COLS" -o "window.dimensions.lines=$ROWS" -o "font.size=$SIZE" -o "font.normal.family=\"$FONT\"" -e sh -c "$CMD" >/dev/null 2>&1 & ;;
  sunset)    "$HERE/../.build/release/sunset-app" --font "$FONT" --size $SIZE --scrollback 100000 -- sh -c "$CMD" >/dev/null 2>&1 & ;;
  *) echo "unknown terminal"; exit 2 ;;
esac
TERMPID=""
for _ in $(seq 1 60); do
  for p in $(pgrep -f "$MARK" || true); do
    c=$(basename "$(ps -o comm= -p "$p" 2>/dev/null)" 2>/dev/null || true)
    case "$c" in *"$T"*) TERMPID=$p; break ;; esac
  done
  [ -n "$TERMPID" ] && break; sleep 0.5
done
[ -n "$TERMPID" ] || { echo "$T: terminal process not found"; exit 1; }
for _ in $(seq 1 600); do [ -f "$DONE" ] && break; sleep 0.5; done; [ -f "$DONE" ] || echo "(output never finished)"
sleep "$SETTLE"
printf '%-10s lines=%-8s pid=%s (%s) ' "$T" "$LINES_N" "$TERMPID" "$(ps -o comm= -p "$TERMPID" | xargs basename)"
"$BIN" "$TERMPID" "$SAMPLE"
rm -f "$DONE"; pkill -f "$MARK" 2>/dev/null || true; kill "$TERMPID" 2>/dev/null || true; sleep 1
