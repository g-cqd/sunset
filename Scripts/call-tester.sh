#!/opt/homebrew/bin/bash
# The local call tester (the owner, 2026-11-19): a page with every API a call site uses (camera, microphone, devices and
# their choice, the speaker, sharing a screen, a window, a tab, with audio, stopping each, a loopback through a real peer
# connection, notifications, full screen, picture in picture, the wake lock), each answer logged on the page.
#
# Serves it on localhost (a secure context, as https is) and opens it in Sunset, or prints the address.
# Usage: Scripts/call-tester.sh [port]      Stop with Ctrl-C.
set -euo pipefail
port="${1:-8767}"
root="$(cd "$(dirname "$0")/../Tools/axdrive/Fixtures" && pwd)"
url="http://127.0.0.1:$port/call.html"
echo "Call tester: $url"
echo "Open it in a Sunset tab (it is opened in the Sunset that is running, if any). Ctrl-C stops the server."
if [ -d "$HOME/Applications/Sunset.app" ]; then
    (sleep 1 && open -a "$HOME/Applications/Sunset.app" "$url") &
fi
cd "$root"
exec python3 -m http.server "$port" --bind 127.0.0.1
