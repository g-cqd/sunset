import Testing

@testable import SunsetConfig

@Suite("Configuration: what changed") struct ConfigurationChangeTests {
    @Test func `the same configuration has no changes`() {
        #expect(Configuration().changes(from: Configuration()).isEmpty)
    }

    @Test func `each group that differs is named once, in a fixed order`() {
        var new = Configuration()
        new.font.size = 18
        new.font.ligatures = false
        new.colors.background = [1, 2, 3]
        new.scrollbackLines = 1
        new.cursorBlinkTimeout = nil
        new.renderer = .cpu
        #expect(new.changes(from: Configuration()) == [.font, .colors, .scrollback, .cursorBlink, .renderer])
    }

    @Test func `one change is one entry`() {
        var new = Configuration()
        new.font.family = "Menlo"
        #expect(new.changes(from: Configuration()) == [.font])
        var colours = Configuration()
        colours.colors.cursor = [255, 0, 0]
        #expect(colours.changes(from: Configuration()) == [.colors])
    }

    @Test func `a window setting is the window group`() {
        var new = Configuration()
        new.window.dragStrip = 20
        #expect(new.changes(from: Configuration()) == [.window])
        var moved = Configuration()
        moved.window.trafficLightsX = 30
        #expect(moved.changes(from: Configuration()) == [.window])
    }

    @Test func `a scroll setting is the scroll group`() {
        var new = Configuration()
        new.scroll.wheel = 1
        #expect(new.changes(from: Configuration()) == [.scroll])
    }
}
