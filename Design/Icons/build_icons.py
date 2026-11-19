#!/usr/bin/env python3
"""Builds Sunset's icons from the masters RenderIcon.swift draws (roadmap 0084).
   swift Design/Icons/RenderIcon.swift .build/icons/masters      draws the masters
   python3 Design/Icons/build_icons.py [masters] [output]       (defaults: .build/icons/masters, .build/icons)
   then copy .build/icons/<variant>/<Name>.icon to App/ (the app builds with those).
For each variant (sunset, twilight, dawn, dusk):
  <Name>.icon               Icon Composer bundle: iOS/iPadOS/macOS 26+, light, dark and tinted; Xcode 26+ also
                            derives the images for older systems from it when the deployment target is lower.
  pre-26/Assets.xcassets    AppIcon.appiconset for an Xcode or a target that does not take .icon: iOS 12+ single 1024
                            (with iOS 18 dark and tinted), and every macOS size (macOS 11+).
  <Name>.icns               for a bundle that names its icon file (CFBundleIconFile).
  previews/                 ictool's own rendering of the .icon for each platform and appearance.
Each output is compiled by actool for what it is for; the script stops if one fails."""
import json, os, shutil, subprocess, sys
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MASTERS = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(REPO, ".build", "icons", "masters")
ROOT = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.join(REPO, ".build", "icons")
IC = "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
VARIANTS = ["sunset", "twilight", "dawn", "dusk"]

def run(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode:
        sys.exit(f"failed: {' '.join(cmd)}\n{r.stdout}\n{r.stderr}")
    return r

def build(name):
    Name = name.capitalize()
    base = os.path.join(ROOT, name)
    shutil.rmtree(base, ignore_errors=True)
    icon = os.path.join(base, f"{Name}.icon")
    os.makedirs(os.path.join(icon, "Assets"))
    for v in ["", "-dark", "-tinted"]:
        shutil.copy(os.path.join(MASTERS, f"{name}{v}.png"), os.path.join(icon, "Assets", f"{name}{v}.png"))
    layer = {"name": "Sky", "glass": False, "image-name-specializations": [
        {"value": f"{name}.png"}, {"appearance": "dark", "value": f"{name}-dark.png"},
        {"appearance": "tinted", "value": f"{name}-tinted.png"}]}
    # The fill, under the image: the image's own colour at its bottom edge, should any of it show.
    px = run(["magick", os.path.join(MASTERS, f"{name}.png"), "-crop", "1024x24+0+1000", "-resize", "1x1!", "-format",
              "%[fx:r],%[fx:g],%[fx:b]", "info:"]).stdout.strip()
    pxd = run(["magick", os.path.join(MASTERS, f"{name}-dark.png"), "-crop", "1024x24+0+1000", "-resize", "1x1!", "-format",
               "%[fx:r],%[fx:g],%[fx:b]", "info:"]).stdout.strip()
    doc = {"fill-specializations": [{"value": {"solid": f"srgb:{px},1.0"}},
                                    {"appearance": "dark", "value": {"solid": f"srgb:{pxd},1.0"}}],
           "groups": [{"layers": [layer], "specular": False, "shadow": {"kind": "none", "opacity": 0},
                       "translucency": {"enabled": False, "value": 0}}],
           "supported-platforms": {"squares": ["iOS", "macOS"]}}
    json.dump(doc, open(os.path.join(icon, "icon.json"), "w"), indent=2)

    prev = os.path.join(base, "previews"); os.makedirs(prev)
    for plat in ["iOS", "macOS"]:
        for r in ["Default", "Dark", "ClearLight", "ClearDark", "TintedLight", "TintedDark"]:
            cmd = [IC, icon, "--export-image", "--output-file", os.path.join(prev, f"{plat}-{r}.png"), "--platform", plat,
                   "--rendition", r, "--width", "512", "--height", "512", "--scale", "1"]
            if r.startswith("Tinted"):
                cmd += ["--tint-color", "0.95", "--tint-strength", "0.7"]
            run(cmd)

    cat = os.path.join(base, "pre-26", "Assets.xcassets", "AppIcon.appiconset"); os.makedirs(cat)
    json.dump({"info": {"author": "xcode", "version": 1}}, open(os.path.join(base, "pre-26", "Assets.xcassets", "Contents.json"), "w"))
    images = [
        {"filename": "ios.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "ios-dark.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "tinted"}], "filename": "ios-tinted.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}]
    for v in ["", "-dark", "-tinted"]:
        shutil.copy(os.path.join(MASTERS, f"{name}{v}.png"), os.path.join(cat, f"ios{v}.png"))
    # macOS before 26: the sky in macOS's rounded square with its margin, as ictool draws the .icon for macOS.
    mac = os.path.join(base, "macOS-1024.png")
    run([IC, icon, "--export-image", "--output-file", mac, "--platform", "macOS", "--rendition", "Default",
         "--width", "1024", "--height", "1024", "--scale", "1"])
    iconset = os.path.join(base, f"{Name}.iconset"); os.makedirs(iconset)
    for pt in [16, 32, 128, 256, 512]:
        for sc in [1, 2]:
            fn = f"mac-{pt}@{sc}x.png"
            run(["sips", "-z", str(pt * sc), str(pt * sc), mac, "--out", os.path.join(cat, fn)])
            images.append({"filename": fn, "idiom": "mac", "scale": f"{sc}x", "size": f"{pt}x{pt}"})
            shutil.copy(os.path.join(cat, fn), os.path.join(iconset, f"icon_{pt}x{pt}{'@2x' if sc == 2 else ''}.png"))
    json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, open(os.path.join(cat, "Contents.json"), "w"), indent=2)
    run(["iconutil", "-c", "icns", iconset, "-o", os.path.join(base, f"{Name}.icns")])
    shutil.rmtree(iconset)

    # Each compiled for what it is for.
    xcassets = os.path.join(base, "pre-26", "Assets.xcassets")
    for plat, target, src, appicon in [("iphoneos", "15.0", xcassets, "AppIcon"), ("macosx", "11.0", xcassets, "AppIcon"),
                                        ("iphoneos", "17.0", icon, Name), ("iphoneos", "26.0", icon, Name),
                                        ("macosx", "14.0", icon, Name), ("macosx", "26.0", icon, Name)]:
        out = f"/tmp/sunset-actool-{name}-{plat}-{target}"
        shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
        r = run(["xcrun", "actool", "--compile", out, "--platform", plat, "--minimum-deployment-target", target,
                 "--app-icon", appicon, "--output-partial-info-plist", os.path.join(out, "p.plist"), src])
        bad = [l for l in r.stdout.splitlines() if "error" in l.lower() or "warning" in l.lower()]
        print(f"{name:9} actool {plat:8} {target:5} {os.path.basename(src):18} ok  {' '.join(sorted(os.listdir(out)))}" + (f"  {bad}" if bad else ""))
        shutil.rmtree(out)

for n in VARIANTS:
    build(n)
