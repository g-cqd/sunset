#!/bin/sh
# WebKit's processes as Sunset's own XPC services, under names of ours (studio.aemi.sunset.engine.*, patch 0037; roadmap
# 0113, ADR-0123, ADR-0124). Every Sunset ships them: the system's WebKit never looks them up (it asks for WebKit's own
# names), ours does. Each runs WebKit's service entry point (Engine/WebKit/service-main.c) with the loader's framework
# path in its executable: the app's own Frameworks (Sunset WebKit), then the engine's folder beside the app.
#
#   Scripts/engine-services.sh templates PRODUCTS   the bundles' Info.plist and resources from a WebKit build, into
#                                                   Engine/WebKit/services (done when the engine changes)
#   Scripts/engine-services.sh add APP              the services into APP/Contents/XPCServices, not signed
#
# Signed by the caller, each with WebKit's identifier (WebKitServiceName in its Info.plist) and the web content ones with
# Engine/WebKit/WebContent.entitlements.
set -eu
cd "$(dirname "$0")/.."
here="$PWD"
templates="$here/Engine/WebKit/services"
prefix=studio.aemi.sunset.engine
buddy=/usr/libexec/PlistBuddy
# Services live inside the WebKit variant's bundle and load from its own Frameworks (ADR-0125).

case "${1:-}" in
    templates)
        products="${2:?usage: Scripts/engine-services.sh templates PRODUCTS}"
        rm -rf "$templates"
        mkdir -p "$templates"
        for service in "$products"/*.xpc; do
            webkitName="$($buddy -c "Print :CFBundleIdentifier" "$service/Contents/Info.plist")"
            ours="$prefix${webkitName#com.apple.WebKit}"
            mkdir -p "$templates/$ours.xpc/Contents"
            cp "$service/Contents/Info.plist" "$templates/$ours.xpc/Contents/Info.plist"
            [ -d "$service/Contents/Resources" ] && ditto "$service/Contents/Resources" "$templates/$ours.xpc/Contents/Resources"
            plist="$templates/$ours.xpc/Contents/Info.plist"
            plutil -convert xml1 "$plist"
            for key in BuildMachineOSBuild DTCompiler DTPlatformBuild DTPlatformName DTPlatformVersion DTSDKBuild DTSDKName \
                DTXcode DTXcodeBuild; do
                $buddy -c "Delete :$key" "$plist" 2>/dev/null || true
            done
            $buddy -c "Set :CFBundleIdentifier $ours" "$plist"
            $buddy -c "Add :WebKitServiceName string $webkitName" "$plist"
        done
        ls "$templates"
        ;;
    add)
        app="${2:?usage: Scripts/engine-services.sh add APP}"
        minimum="$($buddy -c "Print :LSMinimumSystemVersion" "$app/Contents/Info.plist")"
        main="$(mktemp -t sunset-service)"
        clang -O2 -arch arm64 -mmacosx-version-min="$minimum" -framework WebKit \
            "-Wl,-dyld_env,DYLD_FRAMEWORK_PATH=@executable_path/../../../../Frameworks" \
            "$here/Engine/WebKit/service-main.c" -o "$main"
        mkdir -p "$app/Contents/XPCServices"
        for template in "$templates"/*.xpc; do
            copy="$app/Contents/XPCServices/$(basename "$template")"
            rm -rf "$copy"
            ditto "$template" "$copy"
            executable="$($buddy -c "Print :CFBundleExecutable" "$copy/Contents/Info.plist")"
            mkdir -p "$copy/Contents/MacOS"
            cp "$main" "$copy/Contents/MacOS/$executable"
        done
        rm -f "$main"
        ;;
    *)
        echo "usage: Scripts/engine-services.sh templates PRODUCTS | add APP" >&2
        exit 64
        ;;
esac
