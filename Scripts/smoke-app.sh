#!/bin/sh
# Starts a built release Sunset.app once as a test copy, says whether it opened a window, and quits it.
#
#   Scripts/smoke-app.sh [BUILT.app] [FILE]     default: .build/app-release/Sunset.app; FILE is opened with it
#
# A release build is the installed app to the Mac (the same identifier), so it shares the person's defaults, where the
# window's frame is remembered: that frame is read before and written back after (a test copy replaced it twice,
# 2026-11-16, t276). A debug build has an identifier of its own and needs none of this: drive it with axdrive directly.
# The test copy has its own configuration and session (axdrive: SUNSET_CONFIG under /tmp/axdrive), never the person's.
set -eu
cd "$(dirname "$0")/.."

built="${1:-.build/app-release/Sunset.app}"
file="${2:-}"
axdrive="Tools/axdrive/.build/release/axdrive"
domain="studio.aemi.sunset"
key="NSWindow Frame terminal-AppWindow-1"

[ -x "$built/Contents/MacOS/Sunset" ] || { echo "smoke-app: no app at $built" >&2; exit 1; }
[ -x "$axdrive" ] || { echo "smoke-app: build axdrive first (cd Tools/axdrive && swift build -c release)" >&2; exit 1; }

frame="$(defaults read "$domain" "$key" 2>/dev/null || true)"
restore() { if [ -n "$frame" ]; then defaults write "$domain" "$key" "$frame"; fi; }
trap restore EXIT

binary="$(cd "$built/Contents/MacOS" && pwd)/Sunset"
if [ -n "$file" ]; then
    started="$("$axdrive" launch --open "$file" --binary "$binary" | sed -n 1p)"
else
    started="$("$axdrive" launch --binary "$binary" | sed -n 1p)"
fi
pid="${started%% *}"
case "$pid" in
    '' | *[!0-9]*) echo "smoke-app: no window: $started" >&2; exit 1 ;;
esac
echo "windows of $pid:"
"$axdrive" windows "$pid"
"$axdrive" quit "$pid" >/dev/null || { "$axdrive" stop "$pid"; echo "smoke-app: it did not quit by itself" >&2; exit 1; }
rm -rf "${started#* }"
echo "ok"
