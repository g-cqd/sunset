import Testing

@testable import SunsetConfig

/// The owner's note n30 and his answers (2026-11-18): every end "driven from this setting, … set it to alpha for now
/// everywhere"; then "the fading out behind the bar should not use alpha fading …, it should convey that it is a very
/// different setting". `appearance.ends` is how the ends of lists and titles fade; what is under the bars stays
/// `appearance.barBlur`, a setting of its own.
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
