import Testing

@testable import SunsetConfig

/// Shown always, the space under the bar is the page fading under a blur, or a native toolbar.
@Suite("Configuration: what is under a bar shown always")
struct ConfigurationBarBackingTests {
    @Test func `the fade by default; the toolbar read, written, and offered only while the bar is shown always`() throws
    {
        #expect(try ConfigurationParser.parse("{}").configuration.tabs.bar.backing == .fade)
        var configuration = Configuration()
        configuration.tabs.bar.backing = .toolbar
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.tabs.bar.backing == .toolbar)
        let option = try #require(SettingsOption.named("tabs.bar.backing"))
        var shown = Configuration()
        shown.tabs.mode = .internal
        shown.tabs.bar.autoHide = false
        #expect(option.isShown(in: shown))
        shown.tabs.bar.autoHide = true
        #expect(!option.isShown(in: shown), "a bar that hides floats: nothing under it to choose")
    }
}
