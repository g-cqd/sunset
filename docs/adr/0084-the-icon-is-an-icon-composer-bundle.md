---
status: accepted
date: 2026-11-19
---

# 0084 — The icon is an Icon Composer bundle, drawn by a shader in the repository

## Context

The owner asked for icons for iOS and macOS 26 and the systems before, that feel like a real sunset, and variants to choose
from. The old `App/Sunset.icns` was a picture made outside the repository.

## Decision

1. The icon is `App/Sunset.icon`, an Icon Composer bundle (one layer, the sky and a tinted image, no glass, no shadow: the
   sky is the picture). The sky is the same in light and dark: the sun does not get darker with the system's appearance
   (the owner, 2026-11-28). Xcode compiles it into `Assets.car` and into `Sunset.icns` for `CFBundleIconFile`, so macOS before 26
   gets the same icon; `App/Sunset.icns` is no longer kept.
2. Twilight, Dawn and Dusk are alternates in the same catalog (`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`), so the
   person can choose one later without another build. Sunrise, Morning, Noon, Afternoon and Night (2026-11-28) are
   alternates too, offered in Settings only while Option is held; Auto does not use them.
3. The pictures come from `Design/Icons/Sky.metal` (the shader), `Design/Icons/RenderIcon.swift` (which draws it) and `Design/Icons/build_icons.py`; the build
   reproduces the bundles in `App/` byte for byte. A change to an icon is a change there, not to a PNG.
4. For a target that cannot take `.icon`, the build writes an `AppIcon.appiconset` (iOS 12+, iOS 18 tinted; every
   macOS size from 11) and an `.icns` beside each bundle, compiled by `actool` to check them.

## Consequences

The icons are about 12.6 MB in the repository (nine skies × two 1024 px PNGs). The photos the colours were checked against are not
committed (72 MB, each under its own licence). The look was the owner's choice among candidates, not a measurement: it is
not to be "corrected" toward the physics without asking.
