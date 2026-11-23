#!/usr/bin/env bash
# The update packages of a release (roadmap 0122 F, ADR-0122): for each of the last COUNT published releases of the same
# flavour, the package that turns that build into this one, beside the release's zip. Sunset fetches the one from its own
# build when there is one, the zip otherwise.
#
#   Scripts/make-update-packages.sh ZIP [COUNT]     ZIP: Sunset-vX-buildN-macos-arm64.zip or Sunset-WebKit-…; COUNT: 3
#
# Writes <flavour>-<tag>-build<N>-from-build<M>-macos-<arch>.update and its .sha256 beside ZIP, and checks each by applying
# it to the old app and comparing the result with the new one. Needs the network (GitHub's releases, read without an
# account) and about 1 GB of memory per package of the native app.
set -euo pipefail
cd "$(dirname "$0")/.."

zip="${1:?usage: Scripts/make-update-packages.sh ZIP [COUNT]}"
count="${2:-3}"
name="$(basename "$zip")"
case "$name" in
    Sunset-WebKit-*) flavour="Sunset-WebKit" ;;
    Sunset-*) flavour="Sunset" ;;
    *) echo "make-update-packages: $name is not a release zip" >&2; exit 2 ;;
esac
rest="${name#"$flavour"-}"
tag="${rest%%-build*}"
build="${rest#*-build}"; build="${build%%-*}"
arch="${rest##*-macos-}"; arch="${arch%.zip}"
out="$(cd "$(dirname "$zip")" && pwd)"

swift build -c release --product SunsetDeltaTool >&2
tool="$(swift build -c release --show-bin-path)/SunsetDeltaTool"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
ditto -x -k "$zip" "$work/new"
new_app="$(find "$work/new" -maxdepth 1 -name '*.app' | head -1)"

# The last COUNT releases before this one that publish this flavour's archive.
curl -fsSL "https://api.github.com/repos/g-cqd/sunset/releases?per_page=30" |
    /usr/bin/python3 -c '
import json, sys
flavour, build, arch, count = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4])
found = []
for release in json.load(sys.stdin):
    for asset in release["assets"]:
        name = asset["name"]
        if name.startswith(flavour + "-v") and name.endswith("-macos-" + arch + ".zip") and "-build" in name:
            old = int(name.split("-build")[1].split("-")[0])
            if old < build and not release["draft"]:
                found.append((old, asset["browser_download_url"]))
for old, url in sorted(found, reverse=True)[:count]:
    print(old, url)
' "$flavour" "$build" "$arch" "$count" > "$work/olds"

while read -r old url; do
    curl -fsSL -o "$work/old-$old.zip" "$url"
    ditto -x -k "$work/old-$old.zip" "$work/old-$old"
    old_app="$(find "$work/old-$old" -maxdepth 1 -name '*.app' | head -1)"
    package="$flavour-$tag-build$build-from-build$old-macos-$arch.update"
    "$tool" package "$old_app" "$new_app" "$old" "$build" "$out/$package" >&2
    "$tool" stage "$out/$package" "$old_app" "$work/staged-$old.app" >&2
    diff -r "$work/staged-$old.app" "$new_app" > /dev/null || { echo "make-update-packages: $package does not rebuild the new app" >&2; exit 1; }
    (cd "$out" && shasum -a 256 "$package" > "$package.sha256")
    echo "$out/$package"
done < "$work/olds"
