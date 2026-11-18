import Testing

@testable import SunsetConfig

/// Roadmap 0021 S-f (ADR-0071): pages not on screen unload after a delay in hours (12 by default, 0 for never) and under
/// memory pressure (on by default); in Settings > Web > Memory.
@Suite("Pages put to sleep: the settings")
struct ConfigurationPageSleepTests {
    @Test func `12 hours and under pressure by default; read, written and in Settings`() throws {
        let plain = try ConfigurationParser.parse("{}").configuration.web
        #expect(plain.unloadAfter == 12 && plain.unloadUnderPressure)
        let other = try ConfigurationParser.parse(#"{ "web": { "unloadAfter": 0, "unloadUnderPressure": false } }"#)
        #expect(other.issues.isEmpty && other.configuration.web.unloadAfter == 0)
        #expect(!other.configuration.web.unloadUnderPressure)
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: other.configuration))
        #expect(back.issues.isEmpty && back.configuration.web == other.configuration.web)
        let bad = try ConfigurationParser.parse(#"{ "web": { "unloadAfter": 1000 } }"#)
        #expect(
            !bad.issues.isEmpty && bad.configuration.web.unloadAfter == 12,
            "out of range: said, and the default kept"
        )
        #expect(
            SettingsSection.topic("web.memory")?.topic.options.map(\.id) == [
                "web.unloadAfter", "web.unloadUnderPressure"
            ]
        )
    }
}
