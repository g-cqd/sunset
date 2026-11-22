import Testing

@testable import SunsetConfig

/// A tab's colour from its site ("propose variants please"): none, the selected tab, or every tab.
@Suite("Configuration: a tab's colour from its site")
struct ConfigurationSiteColorTests {
    @Test func `off by default; selected and every read, written and offered`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.tabs.siteColor == .off)
        for variant in Configuration.Tabs.SiteColor.allCases {
            var configuration = Configuration()
            configuration.tabs.siteColor = variant
            let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
            #expect(back.issues.isEmpty && back.configuration.tabs.siteColor == variant)
        }
        #expect(
            try ConfigurationParser.parse(#"{"tabs":{"siteColor":"every"}}"#).configuration.tabs.siteColor == .every
        )
        #expect(SettingsOption.named("tabs.siteColor") != nil)
    }
}
