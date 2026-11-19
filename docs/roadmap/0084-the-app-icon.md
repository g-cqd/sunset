---
status: in-progress
blocked-by: nothing
date: 2026-11-19
---

# 0084 — The app's icon, its three alternates, and the first launch's animation (ADR-0084)

The owner, 2026-11-19: icons for iOS and macOS, the latest systems and those before 26; a sky that feels real, from photos and
from physics; "a lighter and a darker variant one could choose at runtime"; an animation the first time Sunset opens on a
desktop, from nothing across the screen and into the window.

| Step | What | Status |
|---|---|---|
| A | References: 12 photos of sunsets and twilight (Wikimedia Commons), each sky's vertical gradient measured | done (in `~/Public/Sunset/photos`, not in the repository: 72 MB, licences per photo) |
| B | The shader and the build (`Design/Icons`): scattering, the sun a glow half in haze; faint lens distortion, shimmer, chromatic aberration, round grain | done |
| C | Four skies, each light, dark and tinted: Sunset (default), Twilight, Dawn, Dusk; chosen by the owner over 12 rounds of candidates | done |
| D | `App/*.icon` the app's icon and alternates; `Sunset.icns` made by Xcode (`CFBundleIconFile`), the hand-made one removed | done: built (release), the icon in the Dock's size seen, the four in `Assets.car` |
| E | iOS and macOS before 26: `.build/icons/<sky>/pre-26` (Assets.xcassets, iOS 12+ and macOS 11+) and `.icns` | done, compiled by actool for iOS 15, 17, 26 and macOS 11, 14, 26; no iOS target in the repository yet to take them |
| F | The person chooses the icon (Settings › General › Icon; `NSApp.applicationIconImage` and the Dock tile) | not started |
| G | The first launch's animation: from nothing, the sky blooming across the screen past the window's bounds, then gathering into the first window (Metal, blur, glow; reduced motion respected) | not started; still frames of the shader only |

Not done: F and G; the icons not seen on a device or in Finder at their small sizes (16, 32 pt) beyond ictool's previews;
watchOS left out (the circle showed the fill at its edges); the photos' licences not checked one by one.
