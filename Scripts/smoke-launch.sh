#!/opt/homebrew/bin/bash
# Launches a test copy of the built app with no accessibility needed: is it alive after ten seconds, and how many windows
# it has. Its own folder (SUNSET_CONFIG, SUNSET_SESSION); the person's saved window frame is put back after.
# Usage: Scripts/smoke-launch.sh [path to Sunset.app]
set -u
app="${1:-.build/app-release/Sunset.app}"
domain=studio.aemi.sunset
key="NSWindow Frame terminal-AppWindow-1"
frame="$(defaults read "$domain" "$key" 2>/dev/null || true)"
folder="$(mktemp -d /tmp/sunset-smoke.XXXXXX)"
echo '{}' > "$folder/config.json"
SUNSET_CONFIG="$folder/config.json" SUNSET_SESSION="$folder/session.json" SUNSET_BACKGROUND=1 \
    "$app/Contents/MacOS/Sunset" > "$folder/out.txt" 2>&1 &
pid=$!
sleep 10
if kill -0 "$pid" 2>/dev/null; then echo "alive after 10 s"; else echo "EXITED"; fi
swift - "$pid" <<'S'
import CoreGraphics
let pid = Int32(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
let mine = list.filter { ($0[kCGWindowOwnerPID as String] as? Int32) == pid && ($0[kCGWindowLayer as String] as? Int) == 0 }
print("windows:", mine.count)
S
kill "$pid" 2>/dev/null
sleep 1
grep -ai "fatal\|crash" "$folder/out.txt" | head -5
if [ -n "$frame" ]; then defaults write "$domain" "$key" -string "$frame"; fi
rm -rf "$folder"
