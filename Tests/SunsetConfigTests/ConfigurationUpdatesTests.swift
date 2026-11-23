import Testing

@testable import SunsetConfig

/// `updates.*` (roadmap 0122, n135): automatic updates, on unless turned off; pre-releases taken, as every release is one.
@Suite("Configuration: updates") struct ConfigurationUpdatesTests {
    @Test func `updates are automatic and take pre-releases unless the file says otherwise`() throws {
        let plain = try ConfigurationParser.parse("{}").configuration.updates
        #expect(plain.automatic && plain.prereleases)
        let result = try ConfigurationParser.parse(#"{ "updates": { "automatic": false, "prereleases": false } }"#)
        #expect(result.issues.isEmpty)
        #expect(!result.configuration.updates.automatic && !result.configuration.updates.prereleases)
        let wrong = try ConfigurationParser.parse(#"{ "updates": { "automatic": "yes", "other": 1 } }"#)
        #expect(wrong.issues.map(\.path).sorted() == ["updates.automatic", "updates.other"])
        #expect(wrong.configuration.updates.automatic)
    }

    @Test func `what is written reads back, and Settings have it under General`() throws {
        var configuration = Configuration()
        configuration.updates.automatic = false
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.updates == configuration.updates)
        #expect(
            SettingsSection.topic("general.updates")?.topic.options.map(\.id) == [
                "updates.center", "updates.automatic", "updates.prereleases"
            ]
        )
    }
}
