#!/usr/bin/env bash
# Notarises and staples a release build signed with the team's Developer ID (task t49), so Gatekeeper opens it on any Mac
# without a warning, offline too. The credentials are the keychain profile `sunset-notary` (xcrun notarytool
# store-credentials, an App Store Connect API key): nothing secret is in the repository.
#
#   Scripts/notarize-app.sh [BUILT.app]     default: .build/app-release/Sunset.app
set -euo pipefail
cd "$(dirname "$0")/.."

app="${1:-.build/app-release/Sunset.app}"
profile="${SUNSET_NOTARY_PROFILE:-sunset-notary}"
[ -x "$app/Contents/MacOS/Sunset" ] || { echo "notarize: no app at $app" >&2; exit 1; }
details="$(codesign -dvv "$app" 2>&1 || true)"
authority="$(printf '%s\n' "$details" | sed -n 's/^Authority=//p' | sed -n 1p)"
case "$authority" in
    "Developer ID Application:"*) ;;
    *) echo "notarize: $app is not signed with a Developer ID (${authority:-ad hoc}); see Signing.xcconfig" >&2; exit 1 ;;
esac
case "$details" in
    *"flags="*"(runtime)"* | *"flags="*",runtime"*) ;;
    *) echo "notarize: $app is not hardened" >&2; exit 1 ;;
esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
ditto -c -k --keepParent "$app" "$work/Sunset.zip"
xcrun notarytool submit "$work/Sunset.zip" --keychain-profile "$profile" --wait
xcrun stapler staple "$app"
spctl --assess --type execute --verbose=2 "$app"
echo "notarized: $app"
