#!/usr/bin/env bash
# Builds Sunset.app from the package (web step g): the executable in a bundle with an Info.plist that gives macOS Sunset's identity (bundle id,
# the usage strings for the camera, the microphone and location, which a page can ask for), a placeholder icon, signed ad hoc.
#
#   Scripts/make-app.sh [debug|release] [output folder]     (default: debug, .build/app)
set -euo pipefail

configuration="${1:-debug}"
output="${2:-.build/app}"
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

swift build --product sunset-app --configuration "$configuration" >/dev/null
binary="$(swift build --product sunset-app --configuration "$configuration" --show-bin-path)/sunset-app"

app="$output/Sunset.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary" "$app/Contents/MacOS/Sunset"

version="$(git describe --tags --always 2>/dev/null || echo 0)"
cat >"$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>studio.aemi.sunset</string>
    <key>CFBundleName</key><string>Sunset</string>
    <key>CFBundleDisplayName</key><string>Sunset</string>
    <key>CFBundleExecutable</key><string>Sunset</string>
    <key>CFBundleIconFile</key><string>Sunset</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>CFBundleVersion</key><string>${version}</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSCameraUsageDescription</key><string>A web page you allow can use the camera.</string>
    <key>NSMicrophoneUsageDescription</key><string>A web page you allow can use the microphone.</string>
    <key>NSLocationUsageDescription</key><string>A web page you allow can know where you are.</string>
    <key>NSLocationWhenInUseUsageDescription</key><string>A web page you allow can know where you are.</string>
</dict>
</plist>
PLIST

# A placeholder icon: an orange square with rounded corners, until Sunset has its own.
iconset="$(mktemp -d)/Sunset.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
    for scale in 1 2; do
        pixels=$((size * scale))
        suffix=""
        if [ "$scale" = 2 ]; then suffix="@2x"; fi
        name="icon_${size}x${size}${suffix}.png"
        magick -size "${pixels}x${pixels}" xc:none -fill '#F28C28' \
            -draw "roundrectangle 0,0 $((pixels - 1)),$((pixels - 1)) $((pixels / 5)),$((pixels / 5))" "$iconset/$name"
    done
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/Sunset.icns"

codesign --force --sign - --timestamp=none --identifier studio.aemi.sunset "$app" >/dev/null 2>&1
echo "$app"
