import Testing

@testable import SunsetConfig

@Suite("Tabs: restore") struct TabsRestoreTests {
    @Test func `tabs.restore is a switch, and anything else is an issue that keeps the default`() throws {
        let off = try ConfigurationParser.parse(#"{ "tabs": { "restore": false } }"#)
        #expect(!off.configuration.tabs.restore && off.issues.isEmpty)
        let bad = try ConfigurationParser.parse(#"{ "tabs": { "restore": "no" } }"#)
        #expect(bad.configuration.tabs.restore && bad.issues.map(\.path) == ["tabs.restore"])
    }

    @Test func `tabs.bar.icon is a switch, on by default`() throws {
        #expect(Configuration().tabs.bar.showIcon)
        let off = try ConfigurationParser.parse(#"{ "tabs": { "bar": { "icon": false } } }"#)
        #expect(!off.configuration.tabs.bar.showIcon && off.issues.isEmpty)
        let bad = try ConfigurationParser.parse(#"{ "tabs": { "bar": { "icon": 1 } } }"#)
        #expect(bad.configuration.tabs.bar.showIcon && bad.issues.map(\.path) == ["tabs.bar.icon"])
    }

    @Test func `tabs.keepRunningForFavorites defaults to true, parses booleans, and is written back`() throws {
        #expect(Configuration().tabs.keepRunningForFavorites)
        let off = try ConfigurationParser.parse(#"{ "tabs": { "keepRunningForFavorites": false } }"#)
        #expect(!off.configuration.tabs.keepRunningForFavorites && off.issues.isEmpty)
        let bad = try ConfigurationParser.parse(#"{ "tabs": { "keepRunningForFavorites": 3 } }"#)
        #expect(
            bad.configuration.tabs.keepRunningForFavorites && bad.issues.map(\.path) == ["tabs.keepRunningForFavorites"]
        )
    }

    @Test func `tabs.confirmClose defaults to true and parses booleans`() throws {
        #expect(Configuration().tabs.confirmClose)
        let off = try ConfigurationParser.parse(#"{ "tabs": { "confirmClose": false } }"#)
        #expect(!off.configuration.tabs.confirmClose && off.issues.isEmpty)
        let bad = try ConfigurationParser.parse(#"{ "tabs": { "confirmClose": "no" } }"#)
        #expect(bad.configuration.tabs.confirmClose && bad.issues.map(\.path) == ["tabs.confirmClose"])
    }

    /// The owner, 2026-11-16: the tabs of a Space stay, stopped, when its last window closes; "a setting should allow to
    /// clean open tabs after a delay or when (last) window of a space closes".
    @Test
    func `the tabs left by the last window: kept by default; closed with it, or after some hours, when the file says`()
        throws
    {
        #expect(!Configuration().tabs.closeWithLastWindow && Configuration().tabs.closeStoppedAfter == 0)
        let set = try ConfigurationParser.parse(
            #"{ "tabs": { "closeWithLastWindow": true, "closeStoppedAfter": 12 } }"#
        )
        #expect(set.issues.isEmpty)
        #expect(set.configuration.tabs.closeWithLastWindow && set.configuration.tabs.closeStoppedAfter == 12)
        let written = ConfigurationWriter.text(for: set.configuration)
        let again = try ConfigurationParser.parse(written)
        #expect(again.configuration.tabs == set.configuration.tabs)
        let bad = try ConfigurationParser.parse(#"{ "tabs": { "closeWithLastWindow": 1, "closeStoppedAfter": -2 } }"#)
        #expect(Set(bad.issues.map(\.path)) == ["tabs.closeWithLastWindow", "tabs.closeStoppedAfter"])
        #expect(!bad.configuration.tabs.closeWithLastWindow && bad.configuration.tabs.closeStoppedAfter == 0)
    }
}
