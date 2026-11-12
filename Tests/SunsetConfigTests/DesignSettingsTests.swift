import SunsetMetrics
import Testing

@testable import SunsetConfig

@Suite("The design system's settings") struct DesignSettingsTests {
    @Test func `the accent follows the system by default; each choice read`() throws {
        #expect(Configuration().appearance.accent == .system)
        for accent in Configuration.Appearance.Accent.allCases {
            let read = try ConfigurationParser.parse(#"{ "appearance": { "accent": ""# + accent.rawValue + #"" } }"#)
            #expect(read.configuration.appearance.accent == accent && read.issues.isEmpty)
        }
    }

    @Test func `the sidebar buttons' keys are read under their old names too`() throws {
        let old = try ConfigurationParser.parse(#"{ "layout": { "pinButtonSize": 30, "pinButtonRadius": 9 } }"#)
        #expect(old.issues.isEmpty)
        #expect(old.configuration.layout.sidebarButtonSize == 30 && old.configuration.layout.sidebarButtonRadius == 9)
        let new = try ConfigurationParser.parse(#"{ "layout": { "sidebarButtonSize": 26 } }"#)
        #expect(new.configuration.layout.sidebarButtonSize == 26 && new.issues.isEmpty)
    }
}
