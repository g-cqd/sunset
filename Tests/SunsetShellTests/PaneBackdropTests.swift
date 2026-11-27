import Testing

@testable import SunsetShell

/// The app's own pages (Settings, Help, Passwords) follow Sunset's scheme, not the terminal theme's.
@Suite("The app's pages' backdrop")
struct PaneBackdropTests {
    @Test func `a dark terminal background gives a light page in light, and stays in dark`() {
        let black = PaneBackdrop(red: 0, green: 0, blue: 0, alpha: 0.9)
        #expect(black.forApp(light: false) == black)
        let light = black.forApp(light: true)
        #expect(!light.isDark && light.alpha == 0.9)
    }

    @Test func `a light terminal background gives a dark page in dark, and stays in light`() {
        let paper = PaneBackdrop(red: 250, green: 250, blue: 245, alpha: 1)
        #expect(paper.forApp(light: true) == paper)
        #expect(paper.forApp(light: false).isDark)
    }
}
