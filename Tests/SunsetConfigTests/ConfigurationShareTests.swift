import Testing

@testable import SunsetConfig

/// `web.shareOtherProfiles` (ADR-0082, the owner's note n49): a page may be offered other profiles' tabs to share; off.
@Suite("Configuration: sharing other profiles' tabs")
struct ConfigurationShareTests {
    @Test func `off by default, read, written, and in Settings`() throws {
        #expect(try !ConfigurationParser.parse("{}").configuration.web.shareOtherProfiles)
        let on = try ConfigurationParser.parse(#"{ "web": { "shareOtherProfiles": true } }"#)
        #expect(on.issues.isEmpty && on.configuration.web.shareOtherProfiles)
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: on.configuration))
        #expect(back.issues.isEmpty && back.configuration.web.shareOtherProfiles)
        #expect(SettingsOption.named("web.shareOtherProfiles") != nil)
    }
}
