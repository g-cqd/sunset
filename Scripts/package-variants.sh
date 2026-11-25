#!/usr/bin/env bash
# The rest of a release after Scripts/package-release.sh (ADR-0125): the WebKit variant of the same Sunset.app, notarized
# and zipped; one `.deltas` archive per variant (the last builds of the same variant, and the other variant at this build);
# their checksums; the signed release index.
#
#   Scripts/package-variants.sh TAG DIST NOTES
#
# DIST holds the native zip package-release.sh wrote; .build/app-package/Sunset.app is the native app it made. The index is
# signed with ~/.config/sunset-signing/release-index-main.pem, or on $SUNSET_SIGN_HOST when that is set.
set -euo pipefail
cd "$(dirname "$0")/.."

tag="${1:?usage: Scripts/package-variants.sh TAG DIST NOTES}"
dist="$(cd "${2:?usage: Scripts/package-variants.sh TAG DIST NOTES}" && pwd)"
notes="${3:?usage: Scripts/package-variants.sh TAG DIST NOTES}"
native=".build/app-package/Sunset.app"
build="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$native/Contents/Info.plist")"
nativeZip="$dist/Sunset-$tag-build$build-macos-arm64.zip"
webkitZip="$dist/Sunset-WebKit-$tag-build$build-macos-arm64.zip"
[ -f "$nativeZip" ] || { echo "package-variants: no $nativeZip (run Scripts/package-release.sh first)" >&2; exit 1; }

Scripts/make-webkit-app.sh "$native" .build/app-webkit-release
Scripts/notarize-app.sh .build/app-webkit-release/Sunset.app
(cd .build/app-webkit-release && ditto -c -k --keepParent Sunset.app "$webkitZip")
(cd "$dist" && shasum -a 256 "$(basename "$webkitZip")" > "$(basename "$webkitZip").sha256")

Scripts/make-update-packages.sh "$nativeZip" 3 "$webkitZip"
Scripts/make-update-packages.sh "$webkitZip" 3 "$nativeZip"
Scripts/sign-release-index.sh "$tag" "$build" "$notes" "$dist" "${SUNSET_SIGN_HOST:-}"
(cd "$dist" && shasum -a 256 -c ./*.sha256)
ls -lh "$dist"
