#!/bin/bash
# Runs main.swift's two phases and looks at the jars between them (t114, 2026-11-19).
set -euo pipefail
here="$(cd "$(dirname "$0")/../../../.." && pwd)"
bin="$here/.build/probes/jarprobe"
swiftc -swift-version 5 "$here/docs/research/probes/cookie-jars/main.swift" -o "$bin" 2>&1 | grep error: || true
codesign -s - -f "$bin" 2>/dev/null
default="$HOME/Library/HTTPStorages/jarprobe.binarycookies"
store="$HOME/Library/WebKit/jarprobe/WebsiteDataStore/6E1F4C2A-0000-4000-8000-00000000A001/Cookies/Cookies.binarycookies"
rm -rf "$default" "$default.moved" "$HOME/Library/WebKit/jarprobe" "$HOME/Library/HTTPStorages/jarprobe"
"$bin" write
for wait in 1 5 15; do
    sleep "$wait"
    printf 'after %2ss: default %s, store %s\n' "$wait" "$( [ -e "$default" ] && echo "written again" || echo absent )" \
        "$( [ -e "$store" ] && echo "written again" || echo absent )"
done
pgrep -fl "com.apple.WebKit.Networking" | grep -c . | sed 's/^/network processes alive: /'
mv "$default.moved" "$default"
mv "$store.moved" "$store"
"$bin" read
rm -rf "$default" "$HOME/Library/WebKit/jarprobe" "$HOME/Library/HTTPStorages/jarprobe"
