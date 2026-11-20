#!/usr/bin/env bash
# A release of Sunset as people download it: the release build, signed with the team's Developer ID, notarised and stapled,
# zipped with ditto, and its SHA-256 beside it. The same script on the owner's Mac and in CI (.github/workflows/release.yml).
#
#   Scripts/package-release.sh TAG [output folder]     TAG: v0.1.0 or v0.1.0-alpha.1; default folder: .build/dist
#
# Signing needs Signing.local.xcconfig (see its .example) and the Developer ID in a keychain; notarising, the credentials
# Scripts/notarize-app.sh reads. SUNSET_SKIP_NOTARY=1 stops after the build (a dry run: the zip is not for people).
set -euo pipefail
cd "$(dirname "$0")/.."

tag="${1:?usage: Scripts/package-release.sh TAG [output folder]}"
output="${2:-.build/dist}"
case "$tag" in
    v[0-9]*.[0-9]*.[0-9]*) ;;
    *) echo "package-release: $tag is not a version tag (v1.2.3 or v1.2.3-alpha.1)" >&2; exit 2 ;;
esac
# CFBundleShortVersionString takes three numbers: the pre-release part stays in the file's name.
version="${tag#v}"
version="${version%%-*}"

app="$(SUNSET_VERSION="$version" Scripts/make-app.sh release .build/app-package | tail -1)"
if [ "${SUNSET_SKIP_NOTARY:-0}" = 1 ]; then
    echo "package-release: not notarised (SUNSET_SKIP_NOTARY=1)" >&2
else
    Scripts/notarize-app.sh "$app"
fi

arch="$(lipo -archs "$app/Contents/MacOS/Sunset" | tr ' ' '-')"
name="Sunset-$tag-macos-$arch.zip"
mkdir -p "$output"
rm -f "$output/$name" "$output/$name.sha256"
ditto -c -k --keepParent "$app" "$output/$name"
(cd "$output" && shasum -a 256 "$name" > "$name.sha256")
cat "$output/$name.sha256"
echo "$output/$name"
