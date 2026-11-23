#!/usr/bin/env bash
# Builds one single range-addressed incremental archive (`SSDLTA2`, ADR-0125) per release zip:
#   <flavour>-<tag>-build<N>-macos-<arch>.deltas (+ .sha256)
# Covers up to COUNT previous builds of the same flavour (default 3) plus optionally the OTHER variant at the same build
# (for fast System WebKit <-> Sunset's WebKit switching), dropping any source whose delta exceeds 65% of the full zip.
# Every included source plan is self-verified by staging and comparing exact BundleManifests (no symlink loops).
#
#   Scripts/make-update-packages.sh ZIP [COUNT] [PEER_ZIP]
#
# Needs the network (GitHub releases API, unauthenticated) to fetch prior release zips.
set -euo pipefail
cd "$(dirname "$0")/.."

zip="${1:?usage: Scripts/make-update-packages.sh ZIP [COUNT] [PEER_ZIP]}"
count="${2:-3}"
peer="${3:-}"
name="$(basename "$zip")"
case "$name" in
    Sunset-WebKit-*) flavour="Sunset-WebKit"; tool_flavour="webkit"; peer_key_prefix="native" ;;
    Sunset-*) flavour="Sunset"; tool_flavour="native"; peer_key_prefix="webkit" ;;
    *) echo "make-update-packages: $name is not a release zip" >&2; exit 2 ;;
esac
rest="${name#"$flavour"-}"
tag="${rest%%-build*}"
build="${rest#*-build}"; build="${build%%-*}"
arch="${rest##*-macos-}"; arch="${arch%.zip}"
out="$(cd "$(dirname "$zip")" && pwd)"
zip_bytes="$(wc -c < "$zip" | tr -d ' ')"
max_bytes=$(( zip_bytes * 65 / 100 ))

swift build -c release --product SunsetDeltaTool >&2
tool="$(swift build -c release --show-bin-path)/SunsetDeltaTool"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
ditto -x -k "$zip" "$work/new"
new_app="$(find "$work/new" -maxdepth 1 -name '*.app' | head -1)"

source_args=()
# Same-build peer variant for fast System <-> Sunset's WebKit switching
if [ -n "$peer" ] && [ -f "$peer" ]; then
    ditto -x -k "$peer" "$work/peer"
    peer_app="$(find "$work/peer" -maxdepth 1 -name '*.app' | head -1)"
    if [ -n "$peer_app" ]; then
        source_args+=("${peer_key_prefix}-${build}:${peer_app}")
    fi
fi

# Last COUNT published releases of the same flavour before `build`
curl -fsSL "https://api.github.com/repos/g-cqd/sunset/releases?per_page=30" |
    /usr/bin/python3 -c '
import json, sys
flavour, build, arch, count = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4])
found = []
for release in json.load(sys.stdin):
    if release.get("draft"): continue
    for asset in release.get("assets", []):
        name = asset["name"]
        if name.startswith(flavour + "-v") and name.endswith("-macos-" + arch + ".zip") and "-build" in name:
            old = int(name.split("-build")[1].split("-")[0])
            if old < build:
                found.append((old, asset["browser_download_url"]))
for old, url in sorted(found, reverse=True)[:count]:
    print(old, url)
' "$flavour" "$build" "$arch" "$count" > "$work/olds"

while read -r old url; do
    [ -n "$old" ] || continue
    curl -fsSL -o "$work/old-$old.zip" "$url"
    ditto -x -k "$work/old-$old.zip" "$work/old-$old"
    old_app="$(find "$work/old-$old" -maxdepth 1 -name '*.app' | head -1)"
    if [ -n "$old_app" ]; then
        source_args+=("${tool_flavour}-${old}:${old_app}")
    fi
done < "$work/olds"

deltas="$flavour-$tag-build$build-macos-$arch.deltas"
"$tool" archive "$tool_flavour" "$build" "$max_bytes" "$new_app" "$out/$deltas" "${source_args[@]}" >&2
(cd "$out" && shasum -a 256 "$deltas" > "$deltas.sha256")
echo "$out/$deltas"
