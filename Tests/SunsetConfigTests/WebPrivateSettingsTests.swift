import Testing

@testable import SunsetConfig

@Suite("Private pages' settings") struct WebPrivateSettingsTests {
    @Test func `no suggestions, a private window's pages share; both read`() throws {
        #expect(!Configuration().web.privateSuggestions && Configuration().web.privateWindowShares)
        let read = try ConfigurationParser.parse(
            #"{ "web": { "privateSuggestions": true, "privateWindowShares": false } }"#
        )
        #expect(
            read.configuration.web.privateSuggestions && !read.configuration.web.privateWindowShares
                && read.issues.isEmpty
        )
    }
}
