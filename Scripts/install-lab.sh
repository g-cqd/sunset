#!/bin/sh
# Puts Sunset Lab in ~/Applications (the owner's note n34): the release build as another app, to try settings and variants
# (the tab bar at the top or the bottom, another material, …) without touching the person's Sunset. It has its own:
#   bundle identifier  studio.aemi.sunset.lab (its own defaults, WebKit data, cookies, permissions in System Settings)
#   folder             ~/Library/Application Support/Sunset Lab (session, history, documents)
#   Keychain items     studio.aemi.sunset.lab.storage-key, .command-seal
#   configuration      ~/.config/sunset-lab/config.json (written once with the tab bar shown, if there is none)
# It does not ask to be the default browser (no URL schemes).
#
#   Scripts/install-lab.sh [BUILT.app]        default: .build/app-release/Sunset.app (Scripts/make-app.sh release .build/app-release)
set -eu
cd "$(dirname "$0")/.."

built="${1:-.build/app-release/Sunset.app}"
target="$HOME/Applications/Sunset Lab.app"
config="${XDG_CONFIG_HOME:-$HOME/.config}/sunset-lab/config.json"

[ -x "$built/Contents/MacOS/Sunset" ] || { echo "install-lab: no app at $built" >&2; exit 1; }
if lsof -a -c Sunset -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | grep -qxF "$target/Contents/MacOS/Sunset"; then
    echo "install-lab: Sunset Lab is running; quit it first" >&2
    exit 1
fi

work="$(mktemp -d)"
ditto "$built" "$work/Sunset Lab.app"
plist="$work/Sunset Lab.app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier studio.aemi.sunset.lab" "$plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName Sunset Lab" "$plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Sunset Lab" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Sunset Lab" "$plist"
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$plist" 2>/dev/null || true
# The identity the build was signed with, else ad hoc.
identity="$(codesign -dvv "$built" 2>&1 | sed -n 's/^Authority=//p' | sed -n 1p)"
codesign --force --deep --sign "${identity:--}" "$work/Sunset Lab.app" 2>/dev/null
codesign --verify "$work/Sunset Lab.app"

rm -rf "$target"
mkdir -p "$(dirname "$target")"
mv "$work/Sunset Lab.app" "$target"
rmdir "$work"

if [ ! -e "$config" ]; then
    mkdir -p "$(dirname "$config")"
    printf '%s\n' '{' '  "tabs": { "mode": "internal", "bar": { "position": "top" } }' '}' >"$config"
    echo "wrote: $config (the tab bar shown, at the top)"
fi
echo "installed: Sunset Lab $(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$target/Contents/Info.plist") at $target"
echo "its settings: $config; its data: ~/Library/Application Support/Sunset Lab"
