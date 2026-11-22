import Testing

@testable import SunsetConfig

/// `sidebar.spaces`: how the Spaces show at the sidebar's foot. `auto`: their icons, and dots once they do not fit (the
/// Space shown keeps its icon); `dots`: dots always, the Space shown made prominent.
@Suite("The Spaces at the sidebar's foot")
struct SpacesStyleTests {
    @Test func `automatic unless the file says dots; anything else is said and left automatic`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.sidebar.spaces == .auto)
        let dots = try ConfigurationParser.parse(#"{ "sidebar": { "spaces": "dots" } }"#)
        #expect(dots.issues.isEmpty && dots.configuration.sidebar.spaces == .dots)
        let odd = try ConfigurationParser.parse(#"{ "sidebar": { "spaces": "stars" } }"#)
        #expect(!odd.issues.isEmpty && odd.configuration.sidebar.spaces == .auto)
        #expect(Configuration.Sidebar.SpacesStyle.allCases.map(\.rawValue) == ["auto", "dots"])
        #expect(SettingsOption.all.contains { $0.id == "sidebar.spaces" })
    }
}
