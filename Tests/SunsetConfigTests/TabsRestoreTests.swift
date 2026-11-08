import Testing

@testable import SunsetConfig

@Suite("Tabs: restore") struct TabsRestoreTests {
    @Test func `tabs.restore is a switch, and anything else is an issue that keeps the default`() throws {
        let off = try ConfigurationParser.parse(#"{ "tabs": { "restore": false } }"#)
        #expect(!off.configuration.tabs.restore && off.issues.isEmpty)
        let bad = try ConfigurationParser.parse(#"{ "tabs": { "restore": "no" } }"#)
        #expect(bad.configuration.tabs.restore && bad.issues.map(\.path) == ["tabs.restore"])
    }
}
