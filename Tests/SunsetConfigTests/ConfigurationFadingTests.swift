import Testing

@testable import SunsetConfig

/// `appearance.ends` is how the ends of lists and titles fade; what is under the bars stays `appearance.barBlur`, a
/// setting of its own.
@Suite("Configuration: how the ends fade")
struct ConfigurationFadingTests {
    @Test func `the ends fade out by default, apart from what is under the bars`() throws {
        let configuration = try ConfigurationParser.parse("{}").configuration
        #expect(configuration.appearance.ends == .fade)
        #expect(configuration.appearance.barBlur == .variable, "under the bars: as before")
        var cut = Configuration()
        cut.appearance.ends = .cut
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: cut))
        #expect(back.issues.isEmpty && back.configuration.appearance.ends == .cut)
        #expect(ConfigurationKeys.all.contains("appearance.ends") && SettingsOption.named("appearance.ends") != nil)
    }
}
