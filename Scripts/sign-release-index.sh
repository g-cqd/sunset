#!/usr/bin/env bash
# Builds and signs `release-index.json` + `release-index.json.sig` (ADR-0125) for a release directory containing the
# packaged zips and `.deltas` archives. Signs with the Ed25519 key on the signing Mac (`~/.config/sunset-signing/release-index-main.pem`).
#
#   Scripts/sign-release-index.sh TAG BUILD NOTES_FILE DIST_DIR [SIGN_HOST]
#
# Set SUNSET_SIGN_HOST (or pass SIGN_HOST) to sign remotely; otherwise uses ~/.config/sunset-signing/release-index-main.pem.
set -euo pipefail
cd "$(dirname "$0")/.."

tag="${1:?usage: Scripts/sign-release-index.sh TAG BUILD NOTES_FILE DIST_DIR [SIGN_HOST]}"
build="${2:?usage: Scripts/sign-release-index.sh TAG BUILD NOTES_FILE DIST_DIR [SIGN_HOST]}"
notes="${3:?usage: Scripts/sign-release-index.sh TAG BUILD NOTES_FILE DIST_DIR [SIGN_HOST]}"
dist="${4:?usage: Scripts/sign-release-index.sh TAG BUILD NOTES_FILE DIST_DIR [SIGN_HOST]}"
host="${5:-}"

swift build -c release --product SunsetDeltaTool >&2
tool="$(swift build -c release --show-bin-path)/SunsetDeltaTool"

specs=()
for pair in "native:Sunset" "webkit:Sunset-WebKit"; do
    flavour="${pair%%:*}"
    prefix="${pair##*:}"
    zip="$dist/$prefix-$tag-build$build-macos-arm64.zip"
    deltas="$dist/$prefix-$tag-build$build-macos-arm64.deltas"
    [ -f "$zip" ] || continue
    [ -f "$deltas" ] || deltas=""
    specs+=("${flavour}:arm64:${zip}:${deltas}")
done

index="$dist/release-index.json"
sig="$dist/release-index.json.sig"
"$tool" index "$tag" "$build" "$notes" "$index" "${specs[@]}" >&2

key="$HOME/.config/sunset-signing/release-index-main.pem"
if [ -z "$host" ] && [ -f "$key" ]; then
    openssl pkeyutl -sign -inkey "$key" -rawin -in "$index" -out "$sig"
else
    target="${host:-${SUNSET_SIGN_HOST:?set SUNSET_SIGN_HOST or install release-index-main.pem locally}}"
    # Sign on the signing host; private key never leaves it.
    ssh "$target" 'bash --norc --noprofile -c "export PATH=/opt/homebrew/bin:\$PATH; tmp=\$(mktemp); trap \"rm -f \$tmp\" EXIT; cat > \$tmp; openssl pkeyutl -sign -inkey ~/.config/sunset-signing/release-index-main.pem -rawin -in \$tmp"' < "$index" > "$sig"
fi
[ "$(wc -c < "$sig" | tr -d ' ')" = "64" ] || { echo "sign-release-index: signature is not 64 bytes" >&2; exit 1; }
echo "$index"
echo "$sig"
