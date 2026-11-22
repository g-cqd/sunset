#!/usr/bin/env bash
# Notarises and staples a release build signed with the team's Developer ID, so Gatekeeper opens it on any Mac
# without a warning, offline too. The credentials: `~/.config/sunset-signing/notary` (key=, key_id=, issuer=: an App Store
# Connect API key, the file and the key 0600), else the keychain profile `sunset-notary` (xcrun notarytool
# store-credentials). The keychain one can need a prompt notarytool cannot show from a script ("User interaction is not
# allowed", 2026-11-19): the file does not. Nothing secret is in the repository.
#
#   Scripts/notarize-app.sh [BUILT.app]     default: .build/app-release/Sunset.app
set -euo pipefail
cd "$(dirname "$0")/.."

app="${1:-.build/app-release/Sunset.app}"
profile="${SUNSET_NOTARY_PROFILE:-sunset-notary}"
notary="$HOME/.config/sunset-signing/notary"
credentials=(--keychain-profile "$profile")
if [ -f "$notary" ]; then
    key="$(sed -n 's/^key=//p' "$notary")"
    key_id="$(sed -n 's/^key_id=//p' "$notary")"
    issuer="$(sed -n 's/^issuer=//p' "$notary")"
    credentials=(--key "$key" --key-id "$key_id" --issuer "$issuer")
fi
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
result="$(xcrun notarytool submit "$work/Sunset.zip" "${credentials[@]}" --wait 2>&1)" || true
printf '%s\n' "$result"
case "$result" in
    *"status: Accepted"*) ;;
    *) echo "notarize: not accepted" >&2; exit 1 ;;
esac
xcrun stapler staple "$app"
spctl --assess --type execute --verbose=2 "$app"
echo "notarized: $app"
