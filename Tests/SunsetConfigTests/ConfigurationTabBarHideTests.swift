import Testing

@testable import SunsetConfig

/// `tabs.bar.autoHide` (roadmap 0055; the owner's notes n41, n42): the built-in bar floats over the page, hidden until the
/// pointer reaches its edge; off, it stays shown.
@Suite("Configuration: the floating tab bar hides")
struct ConfigurationTabBarHideTests {
    @Test func `it hides by default, is read, written, and in Settings with the built-in bar only`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.tabs.bar.autoHide)
        let kept = try ConfigurationParser.parse(#"{ "tabs": { "bar": { "autoHide": false } } }"#)
        #expect(kept.issues.isEmpty && !kept.configuration.tabs.bar.autoHide)
        var configuration = Configuration()
        configuration.tabs.bar.autoHide = false
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && !back.configuration.tabs.bar.autoHide)
        let option = try #require(SettingsOption.named("tabs.bar.autoHide"))
        var native = Configuration()
        native.tabs.mode = .native
        var builtIn = Configuration()
        builtIn.tabs.mode = .internal
        #expect(option.isShown(in: builtIn) && !option.isShown(in: native))
    }
}
