import Testing

@testable import SunsetConfig

@Suite("Asking before quitting") struct QuitSettingsTests {
    @Test func `asks when something would be lost by default; each level read`() throws {
        #expect(Configuration().tabs.askBeforeQuit == .whenLosing)
        for level in Configuration.Tabs.QuitAsk.allCases {
            let read = try ConfigurationParser.parse(#"{ "tabs": { "askBeforeQuit": ""# + level.rawValue + #"" } }"#)
            #expect(read.configuration.tabs.askBeforeQuit == level && read.issues.isEmpty)
        }
    }
}
