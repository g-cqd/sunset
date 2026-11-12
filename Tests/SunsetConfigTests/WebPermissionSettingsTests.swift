import Testing

@testable import SunsetConfig

@Suite("Site permissions' defaults") struct WebPermissionSettingsTests {
    @Test func `asked, except pop-ups and sound; each read; an unknown one is an issue`() throws {
        #expect(Configuration().web.permissions["camera"] == .ask && Configuration().web.permissions["popups"] == .deny)
        let read = try ConfigurationParser.parse(
            #"{ "web": { "permissions": { "camera": "deny", "autoplay": "allow", "nfc": "ask" } } }"#
        )
        #expect(
            read.configuration.web.permissions["camera"] == .deny
                && read.configuration.web.permissions["autoplay"] == .allow
        )
        #expect(
            read.configuration.web.permissions["location"] == .ask && read.issues.map(\.path) == ["web.permissions.nfc"]
        )
    }

    @Test func `they are written back`() throws {
        var configuration = Configuration()
        configuration.web.permissions["screen"] = .deny
        #expect(ConfigurationWriter.literals(for: configuration)["web.permissions.screen"] == #""deny""#)
    }
}
