import Testing

@testable import SunsetConfig

/// Sunset's own password management is a feature scope of its own, off until turned on.
@Suite("The credentials scope")
struct CredentialsScopeTests {
    @Test func `off by default, not counted among the three, read and written`() throws {
        let features = Configuration().features
        #expect(!features.credentials)
        #expect(features.count == 3, "the scopes the app shows; credentials is not a kind of tab")
        let read = try ConfigurationParser.parse(#"{ "features": { "credentials": true } }"#)
        #expect(read.issues.isEmpty && read.configuration.features.credentials)
        #expect(ConfigurationKeys.all.contains("features.credentials"))
        var on = Configuration()
        on.features.credentials = true
        let written = ConfigurationWriter.text(for: on)
        // Written as the file names it now (design 0009); the former name is still read.
        #expect(written.contains("\"passwords\" : true") || written.contains("\"passwords\": true"))
        #expect(
            try ConfigurationParser.parse(#"{ "features": { "passwords": true } }"#).configuration.features.credentials
        )
    }
}
