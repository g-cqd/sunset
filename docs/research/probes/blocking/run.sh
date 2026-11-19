#!/bin/bash
# Builds the probe with Sunset's own BlockingRules sources, optimised, and runs it on copies of the kept lists.
set -euo pipefail
here="$(cd "$(dirname "$0")/../../../.." && pwd)"
out="$here/.build/probes/blocking"
mkdir -p "$out"
cp "$HOME/Library/Application Support/Sunset/Blocking/lists/"*.txt "$out/"
swiftc -O -swift-version 6 -package-name sunset -enable-upcoming-feature InternalImportsByDefault -o "$out/probe" \
    "$here/docs/research/probes/blocking/main.swift" "$here"/Sources/SunsetWeb/Blocking/BlockingRules*.swift 2>&1 | grep error: || true
codesign -s - -f "$out/probe" 2>/dev/null
"$out/probe" "$out"
