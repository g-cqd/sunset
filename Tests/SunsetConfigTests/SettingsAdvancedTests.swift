import Testing

@testable import SunsetConfig

/// Roadmap 0047 G (the owner, 2026-11-18): "try to make the settings more tidy, sorted and not offer all the settings on the
/// first level of them so that you'd find there only the most straightforward ones".
@Suite("Settings: the plainest first, the measures a level down")
struct SettingsAdvancedTests {
    @Test func `every number of the layout is a level down; a topic shows what is not first, and search finds both`()
        throws
    {
        let measures = SettingsOption.all.filter { $0.id.hasPrefix("layout.") }
        #expect(!measures.isEmpty && measures.allSatisfy(\.advanced))
        #expect(SettingsOption.named("tabs.mode")?.advanced == false)
        let floating = try #require(SettingsSection.topic("tabs.floating")?.topic)
        #expect(floating.first.allSatisfy { !$0.advanced } && floating.further.allSatisfy(\.advanced))
        #expect(floating.first.count + floating.further.count == floating.options.count)
        #expect(SettingsOption.all.contains { $0.advanced } && SettingsOption.all.contains { !$0.advanced })
    }

    @Test func `the preview kinds are a level down under their switch`() {
        for id in [
            "sidebar.previewPages", "sidebar.previewTerminals", "sidebar.previewDocuments", "sidebar.previewFolders"
        ] {
            #expect(SettingsOption.named(id)?.advanced == true, "\(id)")
        }
        #expect(SettingsOption.named("sidebar.previews")?.advanced == false)
    }
}
