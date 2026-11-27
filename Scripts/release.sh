#!/usr/bin/env bash
# A whole release of Sunset in one command, as fast as the steps allow: both variants built, notarised, zipped; their
# update packages, the SBOM and the signed index; the signed tag and the GitHub release; the app installed.
#
#   Scripts/release.sh TAG [COMMIT] [--no-install]
#
# COMMIT: the commit to release; by default the newest on main whose CI passed (a release never waits on CI: it takes
# what CI already passed). Its docs/releases/TAG.md is the release's notes.
#
# Fast because:
# - it builds in a release worktree and a build folder that stay between releases (sunset-release in the Shared folder beside the users' homes): the
#   release build is incremental, the packages are not resolved again. The folder names no user: a build records the
#   absolute paths of its sources (ADR-0106), and the built app is checked for the home folder's path;
# - the two notarisations, the SBOM and the update packages' tool run at the same time;
# - an update package covers the latest release before this one only (and the other variant): older installs take the zip.
#
# Needs: Signing.local.xcconfig and the Developer ID (as package-release.sh), the notary credentials (notarize-app.sh), and
# the signing host ($SUNSET_SIGN_HOST, default gcqd-dev) for the index's key, the tag's signature and GitHub.
# The signing host is told what this side knows: its commands' arguments expand here, on purpose.
# shellcheck disable=SC2029
set -euo pipefail
cd "$(dirname "$0")/.."

tag="${1:?usage: Scripts/release.sh TAG [COMMIT] [--no-install]}"
shift
commit=""
install=1
for argument in "$@"; do
    case "$argument" in
        --no-install) install=0 ;;
        *) commit="$argument" ;;
    esac
done
case "$tag" in
    v[0-9]*.[0-9]*.[0-9]*) ;;
    *) echo "release: $tag is not a version tag (v1.2.3 or v1.2.3-alpha.1)" >&2; exit 2 ;;
esac
host="${SUNSET_SIGN_HOST:-gcqd-dev}"
repo="g-cqd/sunset"
vm_repo="Developer/g-cqd/sunset"
started=$SECONDS
phase() { printf '\n== %s (%dm%02ds)\n' "$1" $(((SECONDS - started) / 60)) $(((SECONDS - started) % 60)) >&2; }

phase "commit"
git fetch -q origin main --tags
if [ -z "$commit" ]; then
    commit="$(ssh "$host" "gh run list --repo $repo --workflow CI --branch main --status success --limit 1 --json headSha --jq '.[0].headSha'")"
    [ -n "$commit" ] || { echo "release: no commit of main has passed CI" >&2; exit 1; }
fi
commit="$(git rev-parse --verify "$commit^{commit}")"
echo "releasing $tag at $(git log -1 --format='%h %s' "$commit")" >&2
if git rev-parse -q --verify "refs/tags/$tag" > /dev/null && [ "$(git rev-parse "$tag^{commit}")" != "$commit" ]; then
    echo "release: $tag already names another commit" >&2
    exit 1
fi

# The release worktree, kept between releases, at the commit.
work="${SUNSET_RELEASE_WORKTREE:-$(dirname "$HOME")/Shared/sunset-release}"
if [ ! -d "$work/.git" ] && [ ! -f "$work/.git" ]; then
    git worktree prune
    git worktree add -q --detach "$work" "$commit"
else
    git -C "$work" checkout -q --detach --force "$commit"
    git -C "$work" clean -q -fdx -e .build
fi
[ -f Signing.local.xcconfig ] && cp Signing.local.xcconfig "$work/"
notes_source="$work/docs/releases/$tag.md"
[ -f "$notes_source" ] || { echo "release: no docs/releases/$tag.md at $commit" >&2; exit 1; }
cd "$work"

dist="$work/.build/dist-$tag"
logs="$work/.build/release-logs"
rm -rf "$dist" "$logs" .build/app-package .build/app-webkit-release .build/app-native-copy
mkdir -p "$dist" "$logs"
version="${tag#v}"
version="${version%%-*}"

# Each job in the background, its output in its log; a failure says which, with the end of its log.
pids=()
names=()
start() {
    local name="$1"
    shift
    ("$@") > "$logs/$name.log" 2>&1 &
    pids+=("$!")
    names+=("$name")
}
finish() {
    local failed=0
    for index in "${!pids[@]}"; do
        if ! wait "${pids[$index]}"; then
            echo "release: ${names[$index]} failed; its log ends:" >&2
            tail -25 "$logs/${names[$index]}.log" >&2
            failed=1
        else
            echo "  done: ${names[$index]}" >&2
        fi
    done
    pids=()
    names=()
    [ "$failed" = 0 ] || exit 1
}

phase "build (the release build, incremental) · SBOM · the delta tool"
start sbom Scripts/generate-sbom.sh "$version" "$dist/Sunset-$version.sbom.cdx.json"
start delta-tool swift build -c release --product SunsetDeltaTool
SUNSET_VERSION="$version" SUNSET_DERIVED="$work/.build/release-derived" Scripts/make-app.sh release .build/app-package \
    > "$logs/build.log" 2>&1 || { tail -40 "$logs/build.log" >&2; exit 1; }
finish
native=".build/app-package/Sunset.app"
build="$(plutil -extract CFBundleVersion raw "$native/Contents/Info.plist")"
arch="$(lipo -archs "$native/Contents/MacOS/Sunset" | tr ' ' '-')"
nativeZip="$dist/Sunset-$tag-build$build-macos-$arch.zip"
webkitZip="$dist/Sunset-WebKit-$tag-build$build-macos-$arch.zip"
echo "build $build" >&2
# What the build recorded of where it was made names no user (ADR-0106).
if LC_ALL=C grep -rlqF "$HOME/" "$native/Contents/MacOS" "$native/Contents/Resources" 2> /dev/null; then
    echo "release: the app holds the path $HOME/: built outside the release worktree?" >&2
    exit 1
fi

phase "notarising both variants at once"
# The WebKit variant is made from a copy: notarising staples the native app while the copy is wrapped.
ditto "$native" .build/app-native-copy/Sunset.app
native_variant() {
    Scripts/notarize-app.sh "$native"
    ditto -c -k --keepParent "$native" "$nativeZip"
}
webkit_variant() {
    Scripts/make-webkit-app.sh .build/app-native-copy/Sunset.app .build/app-webkit-release
    Scripts/notarize-app.sh .build/app-webkit-release/Sunset.app
    (cd .build/app-webkit-release && ditto -c -k --keepParent Sunset.app "$webkitZip")
}
start native native_variant
start webkit webkit_variant
finish
for file in "$nativeZip" "$webkitZip" "$dist/Sunset-$version.sbom.cdx.json"; do
    (cd "$dist" && shasum -a 256 "$(basename "$file")" > "$(basename "$file").sha256")
done

phase "update packages (from the latest release, and the other variant)"
start deltas-native Scripts/make-update-packages.sh "$nativeZip" 1 "$webkitZip"
start deltas-webkit Scripts/make-update-packages.sh "$webkitZip" 1 "$nativeZip"
finish

phase "the signed index"
notes="$logs/notes.md"
{ printf 'Build %s.\n\n' "$build"; cat "$notes_source"; } > "$notes"
Scripts/sign-release-index.sh "$tag" "$build" "$notes" "$dist" "$host" > "$logs/index.log" 2>&1 ||
    { tail -20 "$logs/index.log" >&2; exit 1; }
(cd "$dist" && shasum -a 256 -c ./*.sha256 > /dev/null)

phase "the signed tag and the GitHub release"
remote="/tmp/sunset-release-$tag"
ssh "$host" "cd ~/$vm_repo && git fetch -q origin --tags &&
    { git rev-parse -q --verify 'refs/tags/$tag' > /dev/null ||
        { git tag -s '$tag' '$commit' -m 'Sunset $version (build $build)' && git push -q origin '$tag'; }; } &&
    rm -rf '$remote' && mkdir -p '$remote'"
tar -cf - -C "$dist" . | ssh "$host" "tar -xf - -C '$remote'"
scp -q "$notes" "$host:$remote.md"
prerelease=""
case "$tag" in *-*) prerelease="--prerelease" ;; esac
title="Sunset ${tag#v} (build $build)"
# The tag's own workflow may have published its build first: then these assets replace its.
ssh "$host" "cd ~/$vm_repo &&
    if gh release view '$tag' --repo $repo > /dev/null 2>&1; then
        gh release upload '$tag' '$remote'/* --clobber --repo $repo &&
        gh release edit '$tag' --repo $repo --title '$title' --notes-file '$remote.md' $prerelease
    else
        gh release create '$tag' '$remote'/* --repo $repo --title '$title' --notes-file '$remote.md' --verify-tag $prerelease
    fi && rm -rf '$remote' '$remote.md' &&
    gh api repos/$repo/releases/tags/'$tag' --jq '.assets | length'" | {
    read -r count
    [ "$count" -ge 12 ] || { echo "release: the release has $count assets, not 12" >&2; exit 1; }
    echo "published: $count assets" >&2
}

if [ "$install" = 1 ]; then
    phase "installing"
    Scripts/install-app.sh .build/app-webkit-release/Sunset.app >&2
fi
phase "released $tag (build $build)"
echo "https://github.com/$repo/releases/tag/$tag"
