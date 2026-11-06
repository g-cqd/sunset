#!/usr/bin/env bash
# Runs a stream in a Ghostty window (AppleScript), sized to 80x24 cells, and prints the text of its screen (Ghostty's own `write_screen_file` action).
# Ghostty is an oracle run as a process (ADR-0004). Usage: Scripts/oracle-ghostty.sh stream.sh > screen.txt
#
# A Ghostty window will not close while a program runs in it without a prompt, so the program in the window is a small loop that ends when told to:
# the window closes by itself then. If it does not, the foreground process Ghostty reports is killed (that one process, nothing else).
# The system clipboard is used by the screen-file action; its text is saved and put back.
set -u
stream="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
cols=80
rows=24
work="$(mktemp -d)"
cache=/tmp/sunset-ghostty-window-size
cat > "$work/run.sh" <<RUN
#!/bin/sh
export ORACLE_OUT="${ORACLE_OUT:-}"
while [ ! -f "$work/go" ]; do stty size > "$work/size" 2>/dev/null; sleep 0.2; done
/bin/sh "$stream"
touch "$work/done"
while [ ! -f "$work/quit" ]; do sleep 0.2; done
RUN
saved_clipboard="$(pbpaste 2>/dev/null)"

ax() { osascript -e "tell application \"System Events\" to tell process \"Ghostty\" to $1" 2>/dev/null; }

terminal_id="$(osascript <<APPLESCRIPT
tell application "Ghostty"
    set cfg to new surface configuration
    set command of cfg to "/bin/sh $work/run.sh"
    set w to new window with configuration cfg
    return id of focused terminal of selected tab of w
end tell
APPLESCRIPT
)"
[ -n "$terminal_id" ] || { echo "could not open a Ghostty window" >&2; exit 2; }

# Size the window so that the grid is exactly cols x rows: start from the last size that worked, then scale by what the window reports.
read -r width height < <( [ -f "$cache" ] && cat "$cache" || ax 'get size of front window' | tr -d ',' )
for _ in 1 2 3 4 5 6 7 8; do
    ax "set size of front window to {$width, $height}" >/dev/null
    sleep 0.6
    read -r have_rows have_cols < "$work/size" 2>/dev/null || continue
    [ "$have_rows" = "$rows" ] && [ "$have_cols" = "$cols" ] && { echo "$width $height" > "$cache"; break; }
    # Cells scale with the window; the padding is small, so scaling is close and the next pass corrects it.
    width=$(( width * cols / have_cols + (cols > have_cols ? 1 : (cols < have_cols ? -1 : 0)) ))
    height=$(( height * rows / have_rows + (rows > have_rows ? 1 : (rows < have_rows ? -1 : 0)) ))
done
read -r have_rows have_cols < "$work/size" 2>/dev/null
if [ "$have_rows" != "$rows" ] || [ "$have_cols" != "$cols" ]; then
    echo "ghostty window is ${have_cols}x${have_rows}, not ${cols}x${rows}" >&2
fi

touch "$work/go"
for _ in $(seq 1 100); do [ -f "$work/done" ] && break; sleep 0.2; done
sleep 0.5
osascript -e "tell application \"Ghostty\" to perform action \"write_screen_file:copy\" on (first terminal whose id is \"$terminal_id\")" >/dev/null 2>&1
sleep 0.5
file="$(pbpaste)"
if [ -f "$file" ]; then sed -e 's/[[:space:]]*$//' "$file"; fi
printf '%s' "$saved_clipboard" | pbcopy

touch "$work/quit"
ghostty_terminal() { osascript -e "tell application \"Ghostty\" to $1 (first terminal whose id is \"$terminal_id\")" 2>/dev/null; }
# The window stays after its program ends (and cannot be closed without a prompt while the program runs): wait for the loop to end, then close.
for _ in $(seq 1 30); do
    [ "$(ghostty_terminal 'return pid of')" = "0" ] && break
    [ -z "$(ghostty_terminal 'return id of')" ] && break
    sleep 0.3
done
pid="$(ghostty_terminal 'return pid of')"
case "$pid" in
    '' | 0) ;;
    *[!0-9]*) echo "ghostty window $terminal_id: process unknown, close it by hand" >&2 ;;
    *)
        # Only a real process id on that terminal's tty is signalled: Ghostty reports pid 0 when it does not know, and `kill 0` would signal this
        # script's whole process group (it did, once).
        tty="$(ghostty_terminal 'return tty of')"
        if [ "$pid" -gt 1 ] && [ "$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')" = "${tty#/dev/}" ]; then
            kill "$pid" 2>/dev/null
            sleep 0.5
        else
            echo "ghostty window $terminal_id: pid $pid is not on $tty, close it by hand" >&2
        fi ;;
esac
ghostty_terminal 'close' >/dev/null
rm -rf "$work"
