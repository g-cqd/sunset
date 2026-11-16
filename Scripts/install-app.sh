#!/bin/sh
# Puts a built Sunset.app in ~/Applications, and says whether a Sunset that is running is still the build before.
#
#   Scripts/install-app.sh [BUILT.app]        default: .build/app-release/Sunset.app (Scripts/make-app.sh release .build/app-release)
#
# A running Sunset is not stopped, and goes on running the bundle it was started from: that bundle is moved aside under
# .build/replaced, never deleted while a process runs from it, and deleted by a later install once none does. Which bundle a
# process runs from is read with lsof, not ps or pgrep: ps goes on showing the path the process was started at after its
# bundle has been moved, and pgrep leaves out its own ancestors, so it never sees the Sunset this script is run in (that is how
# a fix was installed under a running Sunset and said to be in the owner's hands, 2026-11-16).
set -eu
cd "$(dirname "$0")/.."

built="${1:-.build/app-release/Sunset.app}"
target="$HOME/Applications/Sunset.app"
kept="$PWD/.build/replaced"

[ -x "$built/Contents/MacOS/Sunset" ] || { echo "install-app: no app at $built" >&2; exit 1; }

version() { /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$1/Contents/Info.plist" 2>/dev/null || echo "?"; }

# The executables that processes named Sunset run from, one path a line, as they are now.
running="$(lsof -a -c Sunset -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | grep '/Contents/MacOS/Sunset$' || true)"
runs_from() { printf '%s\n' "$running" | grep -qxF "$1/Contents/MacOS/Sunset"; }

mkdir -p "$kept"
for old in "$kept"/*/Sunset.app; do
    [ -d "$old" ] || continue
    if runs_from "$old"; then
        echo "kept: $old ($(version "$old")): a running Sunset was started from it"
    else
        rm -rf "$(dirname "$old")"
    fi
done

rm -rf "$target.new"
ditto "$built" "$target.new"
stale=""
if [ -d "$target" ]; then
    if runs_from "$target"; then stale="$(version "$target")"; fi
    aside="$kept/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$aside"
    mv "$target" "$aside/Sunset.app"
fi
mkdir -p "$(dirname "$target")"
mv "$target.new" "$target"
codesign --verify "$target"
echo "installed: $(version "$target") at $target"

if [ -z "$stale" ]; then
    for old in "$kept"/*/Sunset.app; do
        [ -d "$old" ] || continue
        if runs_from "$old"; then stale="$(version "$old")"; fi
    done
fi
if [ -n "$stale" ]; then
    echo "NOT IN USE YET: a Sunset that is running is still build $stale. Quit and reopen it to run $(version "$target")."
fi
