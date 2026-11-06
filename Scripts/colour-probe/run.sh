#!/bin/bash
# Colour accuracy of the app on the screen it is on (owner note n10): paints known sRGB colours, takes a screenshot of the window (which carries the display's
# profile), converts it back to sRGB and compares. Needs a GUI session and screen-recording permission; a local probe, not CI.
#   Scripts/colour-probe/run.sh [path to sunset-app]
set -u
here=$(cd "$(dirname "$0")" && pwd)
app=${1:-"$here/../../.build/release/sunset-app"}
out=$(mktemp -d)
swiftc -O "$here/measure.swift" -o "$out/measure" || exit 2
"$app" --size 14 -- "$here/paint.sh" &
app_pid=$!
trap 'kill "$app_pid" 2>/dev/null' EXIT
sleep 6
window=$(osascript -l JavaScript -e "ObjC.import('CoreGraphics'); var l=ObjC.castRefToObject(\$.CGWindowListCopyWindowInfo(1,0)); var out=[]; for (var i=0;i<l.count;i++){var w=ObjC.deepUnwrap(l.objectAtIndex(i)); if(w.kCGWindowOwnerPID==$app_pid) out.push(w.kCGWindowNumber);} out[0]")
screencapture -x -o -l "$window" "$out/window.png" || exit 2
"$out/measure" "$out/window.png" "${TOLERANCE:-3}"
