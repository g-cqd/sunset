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

    @Test func `under the bars: a fading blur by default; each choice read`() throws {
        #expect(Configuration().appearance.barBlur == .variable)
        for blur in Configuration.Appearance.BarBlur.allCases {
            let read = try ConfigurationParser.parse(#"{ "appearance": { "barBlur": ""# + blur.rawValue + #"" } }"#)
            #expect(read.configuration.appearance.barBlur == blur && read.issues.isEmpty)
        }
    }

    @Test func `in a split the window bar opens a margin above the panes by default; each place read`() throws {
        #expect(Configuration().web.splitBar == .margin)
        for place in Configuration.Web.SplitBar.allCases {
            let read = try ConfigurationParser.parse(#"{ "web": { "splitBar": ""# + place.rawValue + #"" } }"#)
            #expect(read.configuration.web.splitBar == place && read.issues.isEmpty)
        }
    }

    /// The owner, 2026-11-20 (notes n64, n65): pages a page opens are shown, and a setting says so.
    @Test func `pages a page opens are shown by default; the file can say not`() throws {
        #expect(Configuration().web.showOpenedPages)
        let read = try ConfigurationParser.parse(#"{ "web": { "showOpenedPages": false } }"#)
        #expect(!read.configuration.web.showOpenedPages && read.issues.isEmpty)
    }

    /// The owner's note n66: links from other apps open in a peek window, by default.
    @Test func `links from other apps peek by default; the file can say not`() throws {
        #expect(Configuration().web.peekLinks)
        let read = try ConfigurationParser.parse(#"{ "web": { "peekLinks": false } }"#)
        #expect(!read.configuration.web.peekLinks && read.issues.isEmpty)
    }

    /// Task t132: which pop-ups open in a pop-up window: those the page sizes, by default.
    @Test func `pop-up windows are for sized pop-ups by default; each choice read`() throws {
        #expect(Configuration().web.popupWindows == .sized)
        for rule in Configuration.Web.PopupWindows.allCases {
            let read = try ConfigurationParser.parse(#"{ "web": { "popupWindows": ""# + rule.rawValue + #"" } }"#)
            #expect(read.configuration.web.popupWindows == rule && read.issues.isEmpty)
        }
    }

    @Test func `the bars' tint follows the scheme by default; each tint read`() throws {
        #expect(Configuration().appearance.barTint == .scheme)
        for tint in Configuration.Appearance.BarTint.allCases {
            let read = try ConfigurationParser.parse(#"{ "appearance": { "barTint": ""# + tint.rawValue + #"" } }"#)
            #expect(read.configuration.appearance.barTint == tint && read.issues.isEmpty)
        }
    }

    @Test func `a new terminal starts in the home folder by default; a path is read`() throws {
        #expect(Configuration().terminal.directory == "~")
        let read = try ConfigurationParser.parse(#"{ "terminal": { "directory": "~/Code" } }"#)
        #expect(read.configuration.terminal.directory == "~/Code" && read.issues.isEmpty)
    }

    @Test func `the light scheme has its own tint, white by default; a colour and none are read`() throws {
        #expect(Configuration().appearance.lightTintColor == [255, 255, 255])
        #expect(Configuration().appearance.lightTintAlpha == 0.8)
        let strength = try ConfigurationParser.parse(#"{ "appearance": { "tint": { "lightAlpha": 0.6 } } }"#)
        #expect(strength.configuration.appearance.lightTintAlpha == 0.6 && strength.issues.isEmpty)
        let read = try ConfigurationParser.parse(##"{ "appearance": { "tint": { "light": "#ffeedd" } } }"##)
        #expect(read.configuration.appearance.lightTintColor == [0xFF, 0xEE, 0xDD] && read.issues.isEmpty)
        let none = try ConfigurationParser.parse(#"{ "appearance": { "tint": { "light": null } } }"#)
        #expect(none.configuration.appearance.lightTintColor == nil && none.issues.isEmpty)
    }
}
