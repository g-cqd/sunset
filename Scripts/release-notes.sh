#!/usr/bin/env bash
# The body of a GitHub release: the build line, the release's changes (docs/releases/TAG.md), then after a `---` line
# what every release says (docs/releases/footer.md). The update window shows only what comes before the `---`
# (ReleaseNotes), so going over several releases shows each one's changes, not the same footer each time.
#
# Usage: Scripts/release-notes.sh TAG BUILD [REPOSITORY]   (REPOSITORY: the checkout to read, default this one)
set -euo pipefail

tag="${1:?usage: release-notes.sh TAG BUILD [REPOSITORY]}"
build="${2:?usage: release-notes.sh TAG BUILD [REPOSITORY]}"
root="${3:-$(cd "$(dirname "$0")/.." && pwd)}"

changes="$root/docs/releases/$tag.md"
[ -f "$changes" ] || { echo "release-notes: no docs/releases/$tag.md" >&2; exit 1; }
base="$(cut -c1-10 "$root/Engine/WebKit/base")"
set -- "$root"/Engine/WebKit/patches/*.patch
patches="$#"

printf 'Build %s.\n\n' "$build"
cat "$changes"
printf '\n---\n\n'
sed -e "s/TAG/$tag/g" -e "s/BASE/$base/g" -e "s/PATCHES/$patches/g" "$root/docs/releases/footer.md"
