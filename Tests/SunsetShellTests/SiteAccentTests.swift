import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Roadmap 0047 H (the owner, 2026-11-18): "derive the color of the focused tab accent color from either the icon of the
/// website or the website theme color themselves".
@Suite("The accent from the site shown")
struct SiteAccentTests {
    @Test func `the site's theme colour first, then its icon's, when either stands out; else the fallback`() {
        let red: [UInt8] = [200, 40, 40]
        let blue: [UInt8] = [30, 90, 210]
        #expect(Design.Accent.site(theme: red, icon: blue) == .color(red: 200, green: 40, blue: 40))
        #expect(
            Design.Accent.site(theme: [250, 250, 250], icon: blue) == .color(red: 30, green: 90, blue: 210),
            "white"
        )
        #expect(Design.Accent.site(theme: [128, 128, 128], icon: blue) == .color(red: 30, green: 90, blue: 210), "grey")
        #expect(Design.Accent.site(theme: [10, 10, 10], icon: nil) == nil, "black, and no icon")
        #expect(Design.Accent.site(theme: nil, icon: nil) == nil)
    }

    @Test func `an icon's colour is its most common colourful one, not its background`() {
        // 2 × 2 RGBA: two white pixels, one blue, one transparent.
        let pixels: [UInt8] = [255, 255, 255, 255, 255, 255, 255, 255, 30, 90, 210, 255, 0, 0, 0, 0]
        #expect(Design.Accent.dominant(rgba: pixels) == [30, 90, 210])
        #expect(Design.Accent.dominant(rgba: [255, 255, 255, 255]) == nil)
    }
}
