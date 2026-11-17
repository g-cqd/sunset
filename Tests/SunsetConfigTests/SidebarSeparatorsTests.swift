import Testing

@testable import SunsetConfig

/// The owner, 2026-11-17: a setting that removes the lines between the Pinned grid, the Favorites and the tabs, their space
/// kept. `sidebar.separators`, on by default; read, written, in Settings.
@Suite("The sidebar's separators")
struct SidebarSeparatorsTests {
    @Test func `the separators are shown unless the file says otherwise`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.sidebar.separators)
        let off = try ConfigurationParser.parse(#"{ "sidebar": { "separators": false } }"#)
        #expect(off.issues.isEmpty && !off.configuration.sidebar.separators)
        var configuration = Configuration()
        configuration.sidebar.separators = false
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && !back.configuration.sidebar.separators)
        #expect(SettingsOption.all.contains { $0.id == "sidebar.separators" })
    }
}
