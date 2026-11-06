#!/bin/bash
# Runs vtebench inside one terminal with identical geometry and font, writes a gnuplot .dat and a log.
# Usage: bench/compete.sh <kitty|kitty-tuned|ghostty|wezterm|alacritty|sunset> [outdir] [max-secs] [max-samples]
# Needs: vtebench (cargo build --release in a clone of alacritty/vtebench), the terminals (research: roadmap 0014).
# Side effect: a window appears on the desktop for the length of the run. Do not touch the machine while it runs; record `uptime` load in the log.
set -euo pipefail
T="$1"; OUT="${2:-/tmp/sunset-bench}"; SECS="${3:-3}"; SAMPLES="${4:-10}"
VTEBENCH="${VTEBENCH:-/tmp/ref/vtebench}"; FONT="JetBrains Mono"; SIZE=14; COLS=120; ROWS=40
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"  # absolute: the benchmark runs after a cd
DAT="$OUT/$T.dat"; LOG="$OUT/$T.log"; DONE="$OUT/$T.done"; rm -f "$DAT" "$DONE" "$LOG"
CMD="cd $VTEBENCH && ./target/release/vtebench --silent --max-secs $SECS --max-samples $SAMPLES --dat $DAT; uptime > $LOG; touch $DONE"
{ echo "terminal=$T date=$(date -u +%FT%TZ) font=$FONT size=$SIZE grid=${COLS}x${ROWS} secs=$SECS samples=$SAMPLES"; uptime; sw_vers -productVersion; sysctl -n machdep.cpu.brand_string; } > "$OUT/$T.env"
case "$T" in
  kitty)     /Applications/kitty.app/Contents/MacOS/kitty --config NONE -o font_family="$FONT" -o font_size=$SIZE -o remember_window_size=no -o initial_window_width=${COLS}c -o initial_window_height=${ROWS}c -o confirm_os_window_close=0 sh -c "$CMD" >/dev/null 2>&1 & PID=$! ;;
  kitty-tuned) /Applications/kitty.app/Contents/MacOS/kitty --config NONE -o input_delay=0 -o repaint_delay=2 -o sync_to_monitor=no -o font_family="$FONT" -o font_size=$SIZE -o remember_window_size=no -o initial_window_width=${COLS}c -o initial_window_height=${ROWS}c -o confirm_os_window_close=0 sh -c "$CMD" >/dev/null 2>&1 & PID=$! ;;
  ghostty)   open -na /Applications/Ghostty.app --args --config-default-files=false --font-family="$FONT" --font-size=$SIZE --window-width=$COLS --window-height=$ROWS --confirm-close-surface=false --quit-after-last-window-closed=true -e sh -c "$CMD" >/dev/null 2>&1; PID="" ;;
  wezterm)   /Applications/WezTerm.app/Contents/MacOS/wezterm --config-file /dev/null --config "initial_cols=$COLS" --config "initial_rows=$ROWS" --config "font_size=$SIZE" --config "font=wezterm.font('$FONT')" start --always-new-process -- sh -c "$CMD" >/dev/null 2>&1 & PID=$! ;;
  alacritty) /tmp/ref/alacritty/target/release/alacritty --config-file /dev/null -o "window.dimensions.columns=$COLS" -o "window.dimensions.lines=$ROWS" -o "font.size=$SIZE" -o "font.normal.family=\"$FONT\"" -e sh -c "$CMD" >/dev/null 2>&1 & PID=$! ;;
  sunset)    "${SUNSET_BIN:-$(cd "$(dirname "$0")/.." && pwd)/.build/release/sunset-app}" --font "$FONT" --size $SIZE --scrollback 100000 -- sh -c "$CMD" >/dev/null 2>&1 & PID=$! ;;
  *) echo "unknown terminal $T"; exit 2 ;;
esac
for _ in $(seq 1 $((SECS * 12 * 2 + 60))); do [ -f "$DONE" ] && break; sleep 1; done
sleep 1; if [ -n "${PID:-}" ]; then kill "$PID" 2>/dev/null || true; else pkill -f "$DONE" 2>/dev/null || true; fi
[ -f "$DONE" ] && echo "done: $DAT" || { echo "TIMEOUT: $T did not finish"; exit 1; }
