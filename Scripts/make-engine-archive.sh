#!/usr/bin/env bash
# The WebKit engine as a release asset (roadmap 0113 C, ADR-0124): Sunset WebKit's Frameworks as one `SunsetEngine`
# folder, zipped, notarized (the zip: frameworks cannot be stapled, Gatekeeper and Sunset ask Apple for their tickets).
#
#   Scripts/make-engine-archive.sh "Sunset WebKit.app" TAG OUT     writes OUT/SunsetEngine-TAG-build<N>-macos-arm64.zip
#
# Sunset puts it beside itself as `SunsetEngine` once every framework meets its requirement (our team, notarized) and its
# WebKit says a later build (SunsetEngineBuild, signed with it: make-webkit-app.sh). Notarization needs the network and
# ~/.config/sunset-signing/notary.
set -euo pipefail
cd "$(dirname "$0")/.."

app="${1:?usage: Scripts/make-engine-archive.sh APP TAG OUT}"
tag="${2:?usage: Scripts/make-engine-archive.sh APP TAG OUT}"
out="${3:?usage: Scripts/make-engine-archive.sh APP TAG OUT}"
webkitPlist="$app/Contents/Frameworks/WebKit.framework/Versions/A/Resources/Info.plist"
build="$(/usr/libexec/PlistBuddy -c "Print :SunsetEngineBuild" "$webkitPlist")" ||
    { echo "make-engine-archive: $app's WebKit says no build (made before SunsetEngineBuild)" >&2; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/SunsetEngine" "$out"
ditto "$app/Contents/Frameworks" "$work/SunsetEngine/Frameworks"
for item in "$work/SunsetEngine/Frameworks"/*; do
    codesign --verify --strict -R="anchor apple generic and certificate leaf[subject.OU] = \"$(codesign -dvv "$app" 2>&1 | sed -n 's/^TeamIdentifier=//p')\"" "$item"
done
name="SunsetEngine-$tag-build$build-macos-arm64.zip"
ditto -c -k --keepParent "$work/SunsetEngine" "$out/$name"

notary="$HOME/.config/sunset-signing/notary"
credentials=(--keychain-profile "${SUNSET_NOTARY_PROFILE:-sunset-notary}")
if [ -f "$notary" ]; then
    credentials=(--key "$(sed -n 's/^key=//p' "$notary")" --key-id "$(sed -n 's/^key_id=//p' "$notary")"
        --issuer "$(sed -n 's/^issuer=//p' "$notary")")
fi
result="$(xcrun notarytool submit "$out/$name" "${credentials[@]}" --wait 2>&1)" || true
case "$result" in
    *"status: Accepted"*) ;;
    *) printf '%s\n' "$result" >&2; echo "make-engine-archive: not accepted" >&2; exit 1 ;;
esac
(cd "$out" && shasum -a 256 "$name" > "$name.sha256")
echo "$out/$name"
