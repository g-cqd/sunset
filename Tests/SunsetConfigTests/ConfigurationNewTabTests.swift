import Testing

@testable import SunsetConfig

/// What Command-T makes, the focused tab's kind (as before) or always a terminal, a page or a document.
@Suite("Configuration: what a new tab is")
struct ConfigurationNewTabTests {
    @Test func `the focused tab's kind by default; each kind read, written and offered`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.tabs.newTab == .focused)
        for variant in Configuration.Tabs.NewTab.allCases {
            var configuration = Configuration()
            configuration.tabs.newTab = variant
            let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
            #expect(back.issues.isEmpty && back.configuration.tabs.newTab == variant)
        }
        #expect(
            try ConfigurationParser.parse(#"{"tabs":{"newTab":"document"}}"#).configuration.tabs.newTab == .document
        )
        #expect(SettingsOption.named("tabs.newTab") != nil)
    }

    /// "A split makes a pane of the same kind, by a setting": a terminal by default, as before.
    @Test func `a new split is a terminal by default; each kind read, written and offered`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.tabs.newSplit == .terminal)
        for variant in Configuration.Tabs.NewTab.allCases {
            var configuration = Configuration()
            configuration.tabs.newSplit = variant
            let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
            #expect(back.issues.isEmpty && back.configuration.tabs.newSplit == variant)
        }
        #expect(SettingsOption.named("tabs.newSplit") != nil)
    }
}
