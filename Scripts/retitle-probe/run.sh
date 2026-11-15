#!/bin/sh
# What a program that renames its tab costs the window (review of 2026-11-15, 2.1; task t265).
#
# A test copy of Sunset (never the person's own) shows one terminal whose "shell" sets the title fifty times a second. The main
# thread is sampled for five seconds, and the samples that pass through the window's chrome are counted.
#
#   Scripts/retitle-probe/run.sh [path to the Sunset binary]      default: the release app of Scripts/make-app.sh release
#   Scripts/retitle-probe/run.sh --count SAMPLE                   counts a sample taken before
#
# Prints: samples of the main thread, those not waiting, and those inside ChromeView.apply, ChromeView.placeButtons and
# SwiftUI's update of the window's title. Shares, not times: they hold on a busy Mac, which times would not.
set -eu
cd "$(dirname "$0")/../.." || exit 1

# Counts the main thread's samples in the file $1.
count() {
    awk '
        /^Call graph:/ { graph = 1; next }
        /^Total number in stack/ { graph = 0 }
        graph && /Thread_[0-9]+/ { main = ($0 ~ /Main Thread|com\.apple\.main-thread/); if (main) total = $1; next }
        main {
            count = 0
            for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+$/) { count = $i; break }
            if ($0 ~ /mach_msg2_trap|mach_msg_trap/) idle += count
            if ($0 ~ / ChromeView\.apply\(\)/) apply += count
            if ($0 ~ / ChromeView\.placeButtons\(\)/) place += count
            if ($0 ~ / closure #1 in BarAppearanceBridge\.updateWindowTitle/) title += count
            if ($0 ~ / -\[NSWindow _dosetTitle:andDefeatWrap:\]/) set += count
        }
        END {
            busy = total - idle
            printf "main thread: %d samples, %d not waiting (%.0f%%)\n", total, busy, total ? 100 * busy / total : 0
            printf "in SwiftUI updating the window title: %d (%.0f%% of not waiting)\n", title, busy ? 100 * title / busy : 0
            printf "  of which AppKit setting the title itself: %d\n", set
            printf "in ChromeView.apply: %d (%.0f%% of not waiting)\n", apply, busy ? 100 * apply / busy : 0
            printf "  of which ChromeView.placeButtons: %d\n", place
        }
    ' "$1"
}
if [ "${1:-}" = "--count" ]; then
    count "$2"
    exit 0
fi

binary="${1:-$PWD/.build/app-release/Sunset.app/Contents/MacOS/Sunset}"
axdrive="Tools/axdrive/.build/release/axdrive"
[ -x "$axdrive" ] || { echo "build Tools/axdrive first (swift build -c release)"; exit 2; }
[ -x "$binary" ] || { echo "no binary at $binary"; exit 2; }

work="$(mktemp -d /tmp/retitle-probe.XXXXXX)"
cat > "$work/retitle.sh" <<'LOOP'
#!/bin/sh
count=0
while :; do
    count=$((count + 1))
    printf '\033]0;title %d\007' "$count"
    sleep 0.02
done
LOOP
chmod +x "$work/retitle.sh"
cat > "$work/session.json" <<'SESSION'
{"favorites": {"contents": [], "favorites": {"nodes": []}}, "version": 2, "windows": [{"contents": [
{"kind": "terminal", "pane": "22222222-2222-4222-8222-222222222222", "state": {"directory": "/tmp"}}],
"workspace": {"items": [{"focused": "22222222-2222-4222-8222-222222222222", "id": "44444444-4444-4444-8444-444444444444",
"layout": {"pane": "22222222-2222-4222-8222-222222222222"}}], "selected": "44444444-4444-4444-8444-444444444444"}}]}
SESSION

launched="$(SHELL="$work/retitle.sh" "$axdrive" launch --session "$work/session.json" --binary "$binary")"
pid="${launched%% *}"
sleep 3
title_before="$("$axdrive" windows "$pid" | head -1)"
/usr/bin/sample "$pid" 5 -file "$work/sample.txt" > /dev/null 2>&1 || true
title_after="$("$axdrive" windows "$pid" | head -1)"
"$axdrive" menu "$pid" "Sunset>Quit Sunset" > /dev/null 2>&1 || kill "$pid" 2> /dev/null || true

echo "window before: $title_before"
echo "window after:  $title_after"
count "$work/sample.txt"
echo "sample kept at $work/sample.txt"
