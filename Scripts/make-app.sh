#!/usr/bin/env bash
# Builds Sunset.app with XcodeGen and xcodebuild from project.yml (the owner, 2026-11-13: no bundle assembled by hand).
#
#   Scripts/make-app.sh [debug|release] [output folder]     (default: debug, .build/app)
#
# Prints where the app is. Signing: Signing.xcconfig (ad hoc), overridden by Signing.local.xcconfig (see there).
set -euo pipefail

configuration="${1:-debug}"
output="${2:-.build/app}"
cd "$(dirname "$0")/.."

case "$configuration" in
    release) scheme_configuration=Release ;;
    *) scheme_configuration=Debug ;;
esac
version="$(git describe --tags --always 2>/dev/null || echo 0)"

xcodegen generate --quiet
# The packages' build plug-in (AemiSDR's Metal shaders) and macros (InternedStrings) are ours: Xcode would ask to trust them in
# its window, which a command line build cannot answer.
log="$(mktemp)"
if ! xcodebuild -project Sunset.xcodeproj -scheme Sunset -configuration "$scheme_configuration" \
    -derivedDataPath .build/xcode -skipPackagePluginValidation -skipMacroValidation \
    CURRENT_PROJECT_VERSION="$version" build >"$log" 2>&1; then
    grep -E "error:|BUILD FAILED" "$log" >&2 || tail -20 "$log" >&2
    exit 1
fi
built=".build/xcode/Build/Products/$scheme_configuration/Sunset.app"
mkdir -p "$output"
rm -rf "$output/Sunset.app"
ditto "$built" "$output/Sunset.app"
details="$(codesign -dvv "$output/Sunset.app" 2>&1 || true)"
signed="$(printf '%s\n' "$details" | sed -n 's/^Authority=//p' | sed -n 1p)"
echo "signed: ${signed:-ad hoc (macOS will ask for its permissions again)}" >&2
echo "$output/Sunset.app"
