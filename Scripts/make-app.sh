#!/usr/bin/env bash
# Builds Sunset.app with XcodeGen and xcodebuild from project.yml: no bundle assembled by hand.
#
#   Scripts/make-app.sh [debug|release] [output folder]     (default: debug, .build/app)
#
# The build number is the count of commits (CFBundleVersion must be numbers, and it grows); SUNSET_VERSION, when set, is the
# version people see (CFBundleShortVersionString, as 0.1.0), else project.yml's. Prints where the app is. Signing: Signing.xcconfig (ad hoc), overridden by Signing.local.xcconfig (see there).
set -euo pipefail

configuration="${1:-debug}"
output="${2:-.build/app}"
cd "$(dirname "$0")/.."

case "$configuration" in
    release) scheme_configuration=Release ;;
    *) scheme_configuration=Debug ;;
esac
build="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
marketing=()
[ -z "${SUNSET_VERSION:-}" ] || marketing=(MARKETING_VERSION="$SUNSET_VERSION")

xcodegen generate --quiet
# The packages' build plug-in (AemiSDR's Metal shaders) and macros (InternedStrings) are ours: Xcode would ask to trust them in
# its window, which a command line build cannot answer.
log="$(mktemp)"
# SUNSET_DERIVED: another build directory (a clean build, to see every warning: an incremental one shows only those of the
# files it compiles again).
derived="${SUNSET_DERIVED:-.build/xcode}"
if ! xcodebuild -project Sunset.xcodeproj -scheme Sunset -configuration "$scheme_configuration" \
    -derivedDataPath "$derived" -skipPackagePluginValidation -skipMacroValidation \
    CURRENT_PROJECT_VERSION="$build" "${marketing[@]}" build >"$log" 2>&1; then
    grep -E "error:|BUILD FAILED" "$log" >&2 || tail -20 "$log" >&2
    exit 1
fi
# No warning ships: Swift 6's isolation diagnostics about Apple's frameworks stay warnings under -warnings-as-errors (until
# Swift 7), so the log is read. Those of the packages Sunset depends on (their checkouts) are theirs, listed, not failed.
ours="$(grep -E "^$PWD/(Sources|Tests)/[^:]+:[0-9]+:[0-9]+: warning:" "$log" | sort -u || true)"
theirs="$({ grep -E ": warning:" "$log" || true; } | { grep -v -E "^$PWD/(Sources|Tests)/" || true; } | sort -u | wc -l | tr -d ' ')"
[ "$theirs" = 0 ] || echo "make-app: $theirs warnings outside Sunset's sources (dependencies, the toolchain); see $log" >&2
if [ -n "$ours" ]; then
    printf 'make-app: warnings in Sunset'"'"'s sources:\n%s\n' "$ours" >&2
    exit 1
fi
built="$derived/Build/Products/$scheme_configuration/Sunset.app"
mkdir -p "$output"
rm -rf "$output/Sunset.app"
ditto "$built" "$output/Sunset.app"
# A build is not the Mac's browser: macOS sent a link from another app to a copy in .build once (2026-11-20, a test copy
# then ran with the person's settings). Only the installed app stays known to Launch Services.
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
case "$output" in
    */Applications | */Applications/) ;;
    *) "$lsregister" -u "$built" "$output/Sunset.app" 2>/dev/null || true ;;
esac
details="$(codesign -dvv "$output/Sunset.app" 2>&1 || true)"
signed="$(printf '%s\n' "$details" | sed -n 's/^Authority=//p' | sed -n 1p)"
echo "signed: ${signed:-ad hoc (macOS will ask for its permissions again)}" >&2
echo "$output/Sunset.app"
