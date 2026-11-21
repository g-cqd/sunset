#!/bin/sh
# Our WebKit (roadmap 0048, ADR-0110): WebKit at the commit in Engine/WebKit/base with the series in Engine/WebKit/patches
# applied, built outside this repository. No WebKit tree is kept here.
#
#   Scripts/webkit.sh fetch            a shallow, sparse clone of the base in $SUNSET_WEBKIT (no LayoutTests, JSTests,
#                                      PerformanceTests, Websites: not needed to build)
#   Scripts/webkit.sh apply            the series on the base, in order, three-way; stops at the first that does not apply
#   Scripts/webkit.sh build            Tools/Scripts/build-webkit --release (hours on a laptop; the log in $SUNSET_WEBKIT.log)
#   Scripts/webkit.sh move COMMIT      the series moved onto another WebKit commit: fetched, applied three-way with rerere,
#                                      Engine/WebKit/base changed only when every patch applied; then build and test
#   Scripts/webkit.sh export           the tree's commits above the base written back as the series (after a patch is
#                                      rewritten by hand)
#
# $SUNSET_WEBKIT: where the tree is; default ~/Developer/g-cqd/webkit-spike/WebKit.
set -eu
cd "$(dirname "$0")/.."
here="$PWD"
tree="${SUNSET_WEBKIT:-$HOME/Developer/g-cqd/webkit-spike/WebKit}"
base="$(cat Engine/WebKit/base)"
patches="$here/Engine/WebKit/patches"
git_wk() { git -C "$tree" -c core.hooksPath=/dev/null -c rerere.enabled=true -c user.name=Gigi \
    -c user.email=42325924+g-cqd@users.noreply.github.com "$@"; }

# The patch `git am` stopped at, by its subject.
stopped() {
    dir="$tree/.git/rebase-apply"
    sed -n 's/^Subject: //p' "$dir/$(printf '%04d' "$(cat "$dir/next")")" | head -1
}

fetch_commit() {
    git_wk fetch -q --depth 1 --filter=blob:none origin "$1"
}

case "${1:-}" in
fetch)
    if [ ! -d "$tree/.git" ]; then
        mkdir -p "$tree"
        git -C "$tree" init -q
        git_wk remote add origin https://github.com/WebKit/WebKit.git
        git_wk config core.sparseCheckout true
        git_wk sparse-checkout set --no-cone '/*' '!/LayoutTests/' '!/JSTests/' '!/PerformanceTests/' '!/Websites/'
    fi
    fetch_commit "$base"
    git_wk checkout -q --detach "$base"
    echo "webkit: $tree at $base"
    ;;
apply)
    git_wk checkout -q --detach "$base"
    set -- "$patches"/*.patch
    [ -e "$1" ] || { echo "webkit: no patches"; exit 0; }
    if ! git_wk am -q -3 "$@"; then
        echo "webkit: \"$(stopped)\" does not apply on $base." >&2
        echo "webkit: rewrite it in $tree (git am --continue), then Scripts/webkit.sh export; never forced." >&2
        exit 1
    fi
    echo "webkit: $# patches on $base"
    ;;
build)
    (cd "$tree" && Tools/Scripts/build-webkit --release) > "$tree.log" 2>&1
    tail -3 "$tree.log"
    ;;
move)
    new="${2:?webkit: move needs a WebKit commit}"
    fetch_commit "$new"
    git_wk checkout -q --detach "$new"
    set -- "$patches"/*.patch
    if ! git_wk am -q -3 "$@"; then
        echo "webkit: \"$(stopped)\" does not apply on $new; Engine/WebKit/base stays $base." >&2
        echo "webkit: rewrite the stopped patch in $tree, git am --continue, Scripts/webkit.sh export, then move again." >&2
        exit 1
    fi
    echo "$new" > Engine/WebKit/base
    echo "webkit: $# patches moved onto $new; now Scripts/webkit.sh build and the tests (ADR-0110: not taken until they pass)"
    ;;
export)
    rm -f "$patches"/*.patch
    git_wk format-patch -q --no-numbered --zero-commit --no-signature --no-stat -o "$patches" "$(cat Engine/WebKit/base)..HEAD"
    ls "$patches"
    ;;
*)
    sed -n '2,17p' "$0"
    exit 2
    ;;
esac
