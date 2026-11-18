import Testing

@testable import SunsetConfig

/// `appearance.haptics` (roadmap 0054 F, the owner's note n11): the trackpad's tap when a click goes through or is blocked,
/// on by default, and turned off here.
@Suite("Configuration: the trackpad's taps")
struct ConfigurationHapticsTests {
    @Test func `on unless the file says otherwise, written and read back, and in Settings`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.appearance.haptics)
        let off = try ConfigurationParser.parse(#"{ "appearance": { "haptics": false } }"#)
        #expect(off.issues.isEmpty && !off.configuration.appearance.haptics)
        var configuration = Configuration()
        configuration.appearance.haptics = false
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && !back.configuration.appearance.haptics)
        #expect(ConfigurationKeys.all.contains("appearance.haptics"))
        #expect(SettingsOption.named("appearance.haptics") != nil)
    }
}
