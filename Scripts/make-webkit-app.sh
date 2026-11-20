#!/bin/sh
# Sunset on our own WebKit (roadmap 0048 C; the owner, 2026-11-20: both builds possible and releasable, one on macOS's
# WebKit, one bundling ours): "Sunset WebKit.app", made from a release build of Sunset and a release build of WebKit with
# our patches (Scripts/webkit.sh build).
#
#   Scripts/make-webkit-app.sh [SUNSET.app] [OUTPUT FOLDER]
#       default: .build/app-release/Sunset.app (Scripts/make-app.sh release .build/app-release), .build/app-webkit
#
# - Its own identifier (studio.aemi.sunset.webkit): its own settings, profiles and website data. A newer WebKit may change
#   its stores so the system's can no longer read them: the two builds never share them.
# - WebKit's frameworks in Contents/Frameworks, its processes (XPC services) in Contents/XPCServices, where an app's own
#   services are looked up (in the build folder they are links beside the frameworks: copied as links, nothing was found
#   and WebKit fell back to the system's, which do not speak ours; seen 2026-11-20).
# - A launcher (Engine/WebKit/launcher.c) is its executable: it points the loader at those frameworks, for Sunset and
#   WebKit's processes, then runs Sunset. Not links rewritten: system frameworks AppKit loads link the system's WebKit, and
#   with links rewritten both WebKits were in the process (seen 2026-11-20). ADR-0111.
# - Signed inside out like the native build (Signing.local.xcconfig's identity, else ad hoc), hardened, with timestamps;
#   Sunset and WebKit's services with one exception, reading the loader's variables (notarization accepts it); library
#   validation stays on. Then Scripts/notarize-app.sh as the native one.
# - Its provisioning profile (an App ID studio.aemi.sunset.webkit), when there is one: $SUNSET_WEBKIT_PROFILE, else
#   ~/.config/sunset-signing/webkit.provisionprofile (beside the notary's credentials, never in the repository). With it,
#   the team entitlements of the native build (App/Sunset.team.entitlements) for this identifier, the team read from the
#   profile; without it, an ad hoc build's (no team keychain group: Sunset keeps its keys in its vault).
# $SUNSET_WEBKIT: the WebKit tree (default ~/Developer/g-cqd/webkit-spike/WebKit).
set -eu
cd "$(dirname "$0")/.."
here="$PWD"
built="${1:-.build/app-release/Sunset.app}"
output="${2:-.build/app-webkit}"
tree="${SUNSET_WEBKIT:-$HOME/Developer/g-cqd/webkit-spike/WebKit}"
products="$tree/WebKitBuild/Release"
[ -x "$built/Contents/MacOS/Sunset" ] || { echo "make-webkit-app: no Sunset at $built" >&2; exit 1; }
[ -d "$products/WebKit.framework" ] || { echo "make-webkit-app: no WebKit build at $products" >&2; exit 1; }

identity="$(sed -n 's/^CODE_SIGN_IDENTITY *= *//p' Signing.local.xcconfig 2>/dev/null | head -1)"
identity="${identity:--}"

app="$output/Sunset WebKit.app"
rm -rf "$app"
mkdir -p "$output"
ditto "$built" "$app"
frameworks="$app/Contents/Frameworks"
services="$app/Contents/XPCServices"
mkdir -p "$frameworks" "$services"
for item in JavaScriptCore.framework WebCore.framework WebKit.framework WebKitLegacy.framework WebGPU.framework \
    WebInspectorUI.framework libwebrtc.dylib libANGLE-shared.dylib; do
    [ -e "$products/$item" ] && ditto "$products/$item" "$frameworks/$item"
done
rm -rf "$frameworks/WebKit.framework/Versions/A/XPCServices" "$frameworks/WebKit.framework/XPCServices"
# What the app never runs: headers and the build's scripts (executable files a notary would have to accept), JavaScriptCore's
# command line shell (jsc).
for framework in "$frameworks"/*.framework; do
    rm -rf "$framework/Headers" "$framework/PrivateHeaders" "$framework/Helpers" \
        "$framework/Versions/A/Headers" "$framework/Versions/A/PrivateHeaders" "$framework/Versions/A/Helpers"
done
for service in "$products"/*.xpc; do
    ditto "$service" "$services/$(basename "$service")"
done

# The launcher as the executable; Sunset beside it.
clang -O2 -Wall -o "$app/Contents/MacOS/Sunset WebKit" "$here/Engine/WebKit/launcher.c"

plist="$app/Contents/Info.plist"
buddy=/usr/libexec/PlistBuddy
$buddy -c "Set :CFBundleExecutable Sunset WebKit" "$plist"
$buddy -c "Set :CFBundleIdentifier studio.aemi.sunset.webkit" "$plist"
$buddy -c "Set :CFBundleName Sunset WebKit" "$plist"
$buddy -c "Delete :CFBundleDisplayName" "$plist" 2>/dev/null || true
$buddy -c "Add :CFBundleDisplayName string Sunset WebKit" "$plist"
base="$(cat "$here/Engine/WebKit/base")"
$buddy -c "Delete :SunsetWebKitBase" "$plist" 2>/dev/null || true
$buddy -c "Add :SunsetWebKitBase string $base" "$plist"
# The native build's profile names its identifier, not this one's: this one's own, when there is one.
rm -f "$app/Contents/embedded.provisionprofile"
profile="${SUNSET_WEBKIT_PROFILE:-$HOME/.config/sunset-signing/webkit.provisionprofile}"
appEntitlements="$here/App/Sunset.entitlements"
teamEntitlements=""
if [ -f "$profile" ] && [ "$identity" != "-" ]; then
    decoded="$(mktemp -t sunset-profile).plist"
    security cms -D -i "$profile" > "$decoded"
    team="$($buddy -c "Print :TeamIdentifier:0" "$decoded")"
    identifier="$($buddy -c "Print :Entitlements:com.apple.application-identifier" "$decoded")"
    rm -f "$decoded"
    [ "$identifier" = "$team.studio.aemi.sunset.webkit" ] || {
        echo "make-webkit-app: $profile is for $identifier, not studio.aemi.sunset.webkit" >&2
        exit 1
    }
    cp "$profile" "$app/Contents/embedded.provisionprofile"
    teamEntitlements="$(mktemp -t sunset-team).plist"
    sed -e "s/\$(TeamIdentifierPrefix)studio\.aemi\.sunset/$team.studio.aemi.sunset.webkit/g" \
        -e "s/\$(DEVELOPMENT_TEAM)/$team/g" "$here/App/Sunset.team.entitlements" > "$teamEntitlements"
    appEntitlements="$teamEntitlements"
fi

# Signed inside out: libraries, frameworks, services, then Sunset and the app.
sign() { # ENTITLEMENTS PATH
    if [ "$identity" = "-" ]; then
        codesign --force --sign - --options runtime ${1:+--entitlements "$1"} "$2"
    else
        codesign --force --sign "$identity" --options runtime --timestamp ${1:+--entitlements "$1"} "$2"
    fi
}
for library in "$frameworks"/*.dylib "$frameworks"/*.framework/Versions/A/Frameworks/*.dylib; do
    [ -f "$library" ] && sign "" "$library"
done
for name in WebGPU JavaScriptCore WebCore WebKitLegacy WebInspectorUI WebKit; do
    [ -d "$frameworks/$name.framework" ] && sign "" "$frameworks/$name.framework"
done
for service in "$services"/*.xpc; do
    case "$service" in
        *WebContent*) sign "$here/Engine/WebKit/WebContent.entitlements" "$service" ;;
        *) sign "$here/Engine/WebKit/Loader.entitlements" "$service" ;;
    esac
done
# Sunset's: the app's own (the team's with a profile, else an ad hoc build's) and the loader's exception.
entitlements="$(mktemp -t sunset-webkit).plist"
cp "$appEntitlements" "$entitlements"
$buddy -c "Add :com.apple.security.cs.allow-dyld-environment-variables bool true" "$entitlements"
sign "$entitlements" "$app/Contents/MacOS/Sunset"
sign "$appEntitlements" "$app/Contents/MacOS/Sunset WebKit"
sign "$appEntitlements" "$app"
rm -f "$entitlements" ${teamEntitlements:+"$teamEntitlements"}
codesign --verify --deep --strict "$app" || { echo "make-webkit-app: the signature does not verify" >&2; exit 1; }

lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
case "$output" in
    */Applications | */Applications/) ;;
    *) "$lsregister" -u "$app" 2>/dev/null || true ;;
esac
size="$(du -sh "$app" | cut -f1)"
set -- "$here"/Engine/WebKit/patches/*.patch
echo "$app ($size; WebKit $base with $# patches; signed: $identity)"
