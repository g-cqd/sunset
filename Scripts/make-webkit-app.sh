#!/bin/sh
# Sunset on its own WebKit (both builds are released: one on macOS's WebKit, one bundling Sunset's): "Sunset WebKit.app", made from a release build of Sunset and a release build of WebKit with
# our patches (Scripts/webkit.sh build).
#
#   Scripts/make-webkit-app.sh [SUNSET.app] [OUTPUT FOLDER]
#       default: .build/app-release/Sunset.app (Scripts/make-app.sh release .build/app-release), .build/app-webkit
#
# - Its own identifier (studio.aemi.sunset.webkit): its own website data. A newer WebKit may change its stores so the
#   system's can no longer read them: the two builds never share them. Sunset's own data (store, settings, the key that seals
#   them) is shared: Sunset's keychain group first, where new items go, then its own, where its key of before is.
# - WebKit's frameworks in Contents/Frameworks, its processes (XPC services) in Contents/XPCServices, where an app's own
#   services are looked up (in the build folder they are links beside the frameworks: copied as links, nothing was found
#   and WebKit fell back to the system's, which do not speak ours; seen 2026-11-20).
# - Sunset is its executable, and finds WebKit there through the loader's framework path its executable sets
#   (LC_DYLD_ENVIRONMENT, @executable_path/../Frameworks: project.yml); WebKit's processes get executables of ours that
#   set it too (Engine/WebKit/service-main.c). Every system framework that links WebKit then binds to ours. Not links
#   rewritten: system frameworks link the system's WebKit, and both were in the process (2026-11-20, 2026-11-23-05). Not the
#   environment's loader variables: that needed an exception of the hardened runtime (CRIT-02).
# - Signed inside out like the native build (Signing.local.xcconfig's identity, else ad hoc), hardened, with timestamps;
#   library validation stays on; the web content process has the JIT's exception. Then Scripts/notarize-app.sh.
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
# WebKit's processes: the app's own services under names of ours (Scripts/engine-services.sh; the native build has them
# too), their loader's path toward the app's Frameworks first.
rm -rf "$services"
Scripts/engine-services.sh add "$app"
servicePrefix=studio.aemi.sunset.engine

plist="$app/Contents/Info.plist"
buddy=/usr/libexec/PlistBuddy
$buddy -c "Set :CFBundleIdentifier studio.aemi.sunset.webkit" "$plist"
$buddy -c "Set :CFBundleName Sunset WebKit" "$plist"
$buddy -c "Delete :CFBundleDisplayName" "$plist" 2>/dev/null || true
$buddy -c "Add :CFBundleDisplayName string Sunset WebKit" "$plist"
base="$(cat "$here/Engine/WebKit/base")"
$buddy -c "Delete :SunsetWebKitBase" "$plist" 2>/dev/null || true
$buddy -c "Add :SunsetWebKitBase string $base" "$plist"
# Where our WebKit looks its processes up (patch 0037).
$buddy -c "Delete :WebKitXPCServicePrefix" "$plist" 2>/dev/null || true
$buddy -c "Add :WebKitXPCServicePrefix string $servicePrefix" "$plist"
# The base's date: the app tells when its engine is likely behind WebKit's security fixes (EngineFreshness).
baseDate="$(git -C "$tree" show -s --format=%cI "$base" 2>/dev/null || true)"
$buddy -c "Delete :SunsetWebKitBaseDate" "$plist" 2>/dev/null || true
[ -n "$baseDate" ] && $buddy -c "Add :SunsetWebKitBaseDate string $baseDate" "$plist"
# The same base in WebKit's own Info.plist, before it is signed: the app refuses a WebKit of another base (an older
# release's swapped in; BundledWebKit.refuseOtherWebKit).
webkitPlist="$frameworks/WebKit.framework/Versions/A/Resources/Info.plist"
$buddy -c "Delete :SunsetWebKitBase" "$webkitPlist" 2>/dev/null || true
$buddy -c "Add :SunsetWebKitBase string $base" "$webkitPlist"
# And the build, which orders engines published as a component (roadmap 0113): signed with it, so that an older engine
# cannot say it is newer (EngineManifest).
$buddy -c "Delete :SunsetEngineBuild" "$webkitPlist" 2>/dev/null || true
$buddy -c "Add :SunsetEngineBuild integer $($buddy -c "Print :CFBundleVersion" "$plist")" "$webkitPlist"
$buddy -c "Delete :SunsetWebKitBaseDate" "$webkitPlist" 2>/dev/null || true
[ -n "$baseDate" ] && $buddy -c "Add :SunsetWebKitBaseDate string $baseDate" "$webkitPlist"
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
    # Its own application identifier; Sunset's keychain group, then its own.
    sed -e "s#<string>\$(TeamIdentifierPrefix)studio\.aemi\.sunset</string>#<string>$team.studio.aemi.sunset</string><string>$team.studio.aemi.sunset.webkit</string>#" \
        -e "/application-identifier/{n;s#<string>.*</string>#<string>$team.studio.aemi.sunset.webkit</string>#;}" \
        -e "s/\$(DEVELOPMENT_TEAM)/$team/g" "$here/App/Sunset.team.entitlements" > "$teamEntitlements"
    appEntitlements="$teamEntitlements"
fi

# Signed inside out: libraries, frameworks, services, then Sunset and the app.
sign() { # ENTITLEMENTS PATH [IDENTIFIER]
    if [ "$identity" = "-" ]; then
        codesign --force --sign - --options runtime ${1:+--entitlements "$1"} ${3:+--identifier "$3"} "$2"
    else
        codesign --force --sign "$identity" --options runtime --timestamp ${1:+--entitlements "$1"} ${3:+--identifier "$3"} "$2"
    fi
}
for library in "$frameworks"/*.dylib "$frameworks"/*.framework/Versions/A/Frameworks/*.dylib; do
    [ -f "$library" ] && sign "" "$library"
done
for name in WebGPU JavaScriptCore WebCore WebKitLegacy WebInspectorUI WebKit; do
    [ -d "$frameworks/$name.framework" ] && sign "" "$frameworks/$name.framework"
done
for service in "$services"/*.xpc; do
    webkitName="$($buddy -c "Print :WebKitServiceName" "$service/Contents/Info.plist")"
    case "$service" in
        *WebContent*) sign "$here/Engine/WebKit/WebContent.entitlements" "$service" "$webkitName" ;;
        *) sign "" "$service" "$webkitName" ;;
    esac
done
# Sunset's: the app's own (the team's with a profile, else an ad hoc build's); no exception for the loader's variables.
sign "$appEntitlements" "$app/Contents/MacOS/Sunset"
sign "$appEntitlements" "$app"
rm -f ${teamEntitlements:+"$teamEntitlements"}
# No part of it may read the environment's loader variables (CRIT-02).
if find "$app" -type f -perm -u+x -print0 | xargs -0 -n1 codesign -d --entitlements - 2>/dev/null |
    grep -q allow-dyld-environment-variables; then
    echo "make-webkit-app: something is signed with allow-dyld-environment-variables" >&2
    exit 1
fi
codesign --verify --deep --strict "$app" || { echo "make-webkit-app: the signature does not verify" >&2; exit 1; }

lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
case "$output" in
    */Applications | */Applications/) ;;
    *) "$lsregister" -u "$app" 2>/dev/null || true ;;
esac
size="$(du -sh "$app" | cut -f1)"
set -- "$here"/Engine/WebKit/patches/*.patch
echo "$app ($size; WebKit $base with $# patches; signed: $identity)"
