#!/bin/sh
# Our WebKit (roadmap 0048, ADR-0110): WebKit at the commit in Engine/WebKit/base with the series in Engine/WebKit/patches
# applied, built outside this repository. No WebKit tree is kept here.
#
#   Scripts/webkit.sh fetch            a shallow, sparse clone of the base in $SUNSET_WEBKIT: no LayoutTests but the
#                                      directories `test` runs, no JSTests, PerformanceTests, Websites
#   Scripts/webkit.sh apply [COMMIT]   the series on the base (or COMMIT), in order, three-way with rerere; a patch
#                                      WebKit already has (a backport, one taken upstream) is dropped and named
#   Scripts/webkit.sh build            Tools/Scripts/build-webkit --release, incremental (the log in $SUNSET_WEBKIT.log)
#   Scripts/webkit.sh test             the suites the series is held to (TestWebKitAPI, layout tests); failures not in
#                                      Engine/WebKit/known-failures fail it
#   Scripts/webkit.sh update [COMMIT]  WebKit's main (or COMMIT) fetched, the series applied, built, tested; only when all
#                                      of that passes is Engine/WebKit/base moved and the series exported again
#   Scripts/webkit.sh export           the tree's commits above the base written back as the series
#   Scripts/webkit.sh status           the base, the series, the tree
#
# $SUNSET_WEBKIT: where the tree is; default ~/Developer/g-cqd/webkit-spike/WebKit.
set -eu
cd "$(dirname "$0")/.."
here="$PWD"
tree="${SUNSET_WEBKIT:-$HOME/Developer/g-cqd/webkit-spike/WebKit}"
base="$(cat Engine/WebKit/base)"
patches="$here/Engine/WebKit/patches"
known="$here/Engine/WebKit/known-failures"
release="$tree/WebKitBuild/Release"
git_wk() { git -C "$tree" -c core.hooksPath=/dev/null -c rerere.enabled=true -c user.name=Gigi \
    -c user.email=42325924+g-cqd@users.noreply.github.com "$@"; }
now() { date +%s; }
took() { echo "webkit: $1 in $(($(now) - $2)) s"; }

# The TestWebKitAPI suites and layout tests the series is held to.
# Swift Testing suites match by prefix; gtest ones need ".*".
api_suites="WKWebExtensionAPI WKWebExtensionMatchPattern DOMLinearTime HTMLParserSiblingRuns DocumentOrder.* Position.* TextIteratorTest.* StaticRangeValidity.*"
layout_tests="fast/dom/Range fast/selectors fast/css-grid-layout/remove-grid-deferred-deletion.html"
# What the sparse checkout takes of LayoutTests, for those (and WPT runs by hand: diary 2026-11-21-08).
test_paths='/LayoutTests/TestExpectations
/LayoutTests/platform/mac/TestExpectations
/LayoutTests/platform/mac-wk2/TestExpectations
/LayoutTests/platform/wk2/TestExpectations
/LayoutTests/resources/
/LayoutTests/fast/dom/Range/
/LayoutTests/fast/selectors/
/LayoutTests/fast/css-grid-layout/
/LayoutTests/platform/mac/fast/selectors/
/LayoutTests/platform/mac-wk2/fast/selectors/
/LayoutTests/platform/glib/fast/selectors/
/LayoutTests/imported/w3c/resources/
/LayoutTests/imported/w3c/web-platform-tests/resources/
/LayoutTests/imported/w3c/web-platform-tests/common/
/LayoutTests/imported/w3c/web-platform-tests/css/support/
/LayoutTests/imported/w3c/web-platform-tests/css/selectors/
/LayoutTests/imported/w3c/web-platform-tests/dom/'

# The patch `git am` stopped at, by its subject.
stopped() {
    dir="$tree/.git/rebase-apply"
    sed -n 's/^Subject: //p' "$dir/$(printf '%04d' "$(cat "$dir/next")")" | head -1
}

fetch_commit() {
    git_wk fetch -q --depth 1 --filter=blob:none origin "$1"
}

# The series on COMMIT, three-way; a patch whose changes the commit has already (it applies in reverse) is left out.
apply_series() {
    target="$1"
    git_wk checkout -q --detach "$target"
    : > "$tree.dropped"
    keep=""
    for patch in "$patches"/*.patch; do
        [ -e "$patch" ] || continue
        if git_wk apply --check -R "$patch" 2> /dev/null; then
            echo "webkit: already in $target, left out: $(sed -n 's/^Subject: //p' "$patch" | head -1)" | tee -a "$tree.dropped"
            continue
        fi
        keep="$keep $patch"
    done
    [ -n "$keep" ] || { echo "webkit: no patches"; return 0; }
    # shellcheck disable=SC2086 # one word per patch file; their names have no spaces
    if ! git_wk am -q -3 --empty=drop $keep; then
        echo "webkit: \"$(stopped)\" does not apply on $target." >&2
        echo "webkit: rewrite it in $tree (git am --continue), then Scripts/webkit.sh export; never forced." >&2
        return 1
    fi
    echo "webkit: $(echo "$keep" | wc -w | tr -d ' ') patches on $target"
}

build_tree() {
    start="$(now)"
    if ! (cd "$tree" && Tools/Scripts/build-webkit --release) > "$tree.log" 2>&1; then
        grep 'error:' "$tree.log" | sort -u | head -20 >&2
        echo "webkit: the build failed; the log in $tree.log" >&2
        return 1
    fi
    took "built" "$start"
}

# TestWebKitAPI and the layout tests; a failure not named in Engine/WebKit/known-failures fails the run.
test_tree() {
    start="$(now)"
    log="$tree.tests"
    : > "$log"
    set -f
    for suite in $api_suites; do
        DYLD_FRAMEWORK_PATH="$release" DYLD_LIBRARY_PATH="$release" __XPC_DYLD_FRAMEWORK_PATH="$release" \
            __XPC_DYLD_LIBRARY_PATH="$release" "$release/TestWebKitAPI" --filter "$suite" >> "$log" 2>&1 || true
    done
    set +f
    passed="$(grep -c '^\*\*PASS' "$log" || true)"
    grep '^\*\*FAIL' "$log" | sed 's/^\*\*FAIL\*\* //' | sort -u > "$log.failed" || true
    grep -v -e '^#' -e '^$' "$known" > "$log.known" 2> /dev/null || true
    if [ -s "$log.known" ]; then
        unexpected="$(grep -v -F -f "$log.known" "$log.failed" || true)"
    else
        unexpected="$(cat "$log.failed")"
    fi
    echo "webkit: TestWebKitAPI $passed passed, $(wc -l < "$log.failed" | tr -d ' ') failed"
    # shellcheck disable=SC2086 # one word per test path
    (cd "$tree" && Tools/Scripts/run-webkit-tests --release --no-build --no-show-results --no-new-test-results \
        --child-processes=6 $layout_tests) > "$log.layout" 2>&1 || true
    git_wk checkout -q -- LayoutTests 2> /dev/null || true
    layout="$(grep -E 'tests ran as expected' "$log.layout" | tail -1)"
    echo "webkit: layout tests: ${layout:-no summary (see $log.layout)}"
    took "tested" "$start"
    if [ -n "$unexpected" ] || ! echo "$layout" | grep -q '^All '; then
        [ -z "$unexpected" ] || printf 'webkit: unexpected failures:\n%s\n' "$unexpected" >&2
        return 1
    fi
}

case "${1:-}" in
fetch)
    if [ ! -d "$tree/.git" ]; then
        mkdir -p "$tree"
        git -C "$tree" init -q
        git_wk remote add origin https://github.com/WebKit/WebKit.git
        git_wk config core.sparseCheckout true
    fi
    # shellcheck disable=SC2086 # one word per path
    git_wk sparse-checkout set --no-cone '/*' '!/LayoutTests/' '!/JSTests/' '!/PerformanceTests/' '!/Websites/' $test_paths
    fetch_commit "$base"
    git_wk checkout -q --detach "$base"
    echo "webkit: $tree at $base"
    ;;
apply)
    target="${2:-$base}"
    [ "$target" = "$base" ] || fetch_commit "$target"
    apply_series "$target"
    ;;
build)
    build_tree
    ;;
test)
    test_tree
    ;;
update)
    start="$(now)"
    if [ -n "${2:-}" ]; then
        new="$2"
        fetch_commit "$new"
    else
        git_wk fetch -q --depth 1 --filter=blob:none origin main
        new="$(git_wk rev-parse FETCH_HEAD)"
    fi
    [ "$new" != "$base" ] || { echo "webkit: already on $base"; exit 0; }
    apply_series "$new" || exit 1
    build_tree || { echo "webkit: Engine/WebKit/base stays $base; the tree is on $new to fix" >&2; exit 1; }
    test_tree || { echo "webkit: Engine/WebKit/base stays $base; the tree is on $new to fix" >&2; exit 1; }
    echo "$new" > Engine/WebKit/base
    rm -f "$patches"/*.patch
    git_wk format-patch -q --no-numbered --zero-commit --no-signature --no-stat -o "$patches" "$new..HEAD"
    took "moved onto $new ($(find "$patches" -name '*.patch' | wc -l | tr -d ' ') patches)" "$start"
    [ ! -s "$tree.dropped" ] || cat "$tree.dropped"
    ;;
export)
    rm -f "$patches"/*.patch
    git_wk format-patch -q --no-numbered --zero-commit --no-signature --no-stat -o "$patches" "$base..HEAD"
    ls "$patches"
    ;;
status)
    echo "webkit: base $base, $(find "$patches" -name '*.patch' | wc -l | tr -d ' ') patches"
    echo "webkit: tree $(git_wk rev-parse --short HEAD), $(git_wk rev-list --count "$base..HEAD" 2> /dev/null || echo '?') commits above the base"
    git_wk status --short | head -5
    ;;
*)
    sed -n '2,20p' "$0"
    exit 2
    ;;
esac
