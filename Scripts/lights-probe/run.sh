#!/bin/sh
# Where the window's buttons (the traffic lights) are drawn three seconds after Sunset starts, with and without a recording of
# the screen running (diary 2026-11-15: while the screen is recorded AppKit lays its title bar out again as the window shows,
# and the buttons were left at its place, the top left).
#
# A test copy of Sunset (never the person's own) is started for each line. The recording leaves out every window that was
# open when it started, so nothing of the person's screen is in it; it is not kept.
#
#   Scripts/lights-probe/run.sh [path to the Sunset binary]      default: the release app of Scripts/make-app.sh release
#
# Prints, for each configuration, the window's width and the top left corner of each thing drawn in its top 35 pt (the three
# buttons, and the sidebar's pin). Needs Screen Recording for the terminal that runs it.
set -eu
cd "$(dirname "$0")/../.." || exit 1
binary="${1:-$PWD/.build/app-release/Sunset.app/Contents/MacOS/Sunset}"
axdrive="Tools/axdrive/.build/release/axdrive"
[ -x "$axdrive" ] || { echo "build Tools/axdrive first (swift build -c release)"; exit 2; }
[ -x "$binary" ] || { echo "no binary at $binary"; exit 2; }

work="$(mktemp -d /tmp/lights-probe.XXXXXX)"
swiftc -O Scripts/lights-probe/record/main.swift -o "$work/record" 2> /dev/null
swiftc -O Scripts/lights-probe/ink/main.swift -o "$work/ink" 2> /dev/null
cat > "$work/session.json" <<'SESSION'
{"favorites": {"contents": [], "favorites": {"nodes": []}}, "version": 2, "windows": [{"contents": [
{"kind": "terminal", "pane": "22222222-2222-4222-8222-222222222222", "state": {"directory": "/tmp"}}],
"workspace": {"items": [{"focused": "22222222-2222-4222-8222-222222222222", "id": "44444444-4444-4444-8444-444444444444",
"layout": {"pane": "22222222-2222-4222-8222-222222222222"}}], "selected": "44444444-4444-4444-8444-444444444444"}}]}
SESSION

# $1: what the line says; $2: the configuration; $3: "recording" to record the screen meanwhile.
one() {
    recorder=""
    if [ "$3" = "recording" ]; then
        "$work/record" 0 0 400 300 6 "$work/frames" > /dev/null 2>&1 &
        recorder=$!
        sleep 1.5
    fi
    launched="$(SHELL=/bin/cat "$axdrive" launch --session "$work/session.json" --config "$2" --binary "$binary")"
    pid="${launched%% *}"
    sleep 3
    width="$("$axdrive" windows "$pid" | grep -v '""' | head -1 | awk '{print $(NF-1)}')"
    "$axdrive" shot "$pid" "$work/shot.png" > /dev/null 2>&1
    "$axdrive" menu "$pid" "Sunset>Quit Sunset" > /dev/null 2>&1 || kill "$pid" 2> /dev/null || true
    [ -z "$recorder" ] || wait "$recorder" || true
    drawn="$("$work/ink" "$work/shot.png" | sed -E 's/ink x ([0-9.]+)\.\.\.[0-9.]+ pt, y ([0-9.]+)\.\.\..*/(\1,\2)/' | tr '\n' ' ')"
    echo "$1: window $width pt wide, drawn at $drawn"
    sleep 1.2
}

one "sidebar on the right" '{}' no
one "sidebar on the right, recording" '{}' recording
one "sidebar on the left, recording" '{"sidebar":{"side":"left"}}' recording
one "no sidebar, recording" '{"sidebar":{"enabled":false}}' recording
one "the sidebar hides, recording" '{"sidebar":{"autoHide":true}}' recording
one "the system's title bar" '{"window":{"decorations":"native"}}' no
rm -rf "$work"
