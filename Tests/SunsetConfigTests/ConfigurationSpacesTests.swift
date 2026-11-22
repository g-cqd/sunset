import Testing

@testable import SunsetConfig

/// Whose the Favorites and the Pinned grid are. By default the Favorites are each Space's and the grid each profile's;
/// read, written, and in Settings > General > Spaces.
@Suite("Whose the Favorites and the Pinned grid are")
struct ConfigurationSpacesTests {
    @Test func `favorites by Space and the grid by profile unless the file says otherwise`() throws {
        let plain = try ConfigurationParser.parse("{}").configuration.spaces
        #expect(plain.favorites == .space && plain.pinned == .profile)
        let other = try ConfigurationParser.parse(#"{ "spaces": { "favorites": "profile", "pinned": "app" } }"#)
        #expect(other.issues.isEmpty && other.configuration.spaces.favorites == .profile)
        #expect(other.configuration.spaces.pinned == .app)
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: other.configuration))
        #expect(back.issues.isEmpty && back.configuration.spaces == other.configuration.spaces)
        #expect(
            SettingsSection.topic("general.spaces")?.topic.options.map(\.id) == ["spaces.favorites", "spaces.pinned"]
        )
    }
}
