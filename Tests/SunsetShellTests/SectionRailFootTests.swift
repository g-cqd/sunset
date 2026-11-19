import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner's note n27 (2026-11-18): "we could add an help icon above the settings icon in the library vertical section
/// bar".
@Suite("The Library's foot")
struct SectionRailFootTests {
    @Test func `Help is above the gear, the way back last`() {
        #expect(SectionRail.foot(hasHelp: true) == [.help, .settings, .back])
        #expect(SectionRail.foot(hasHelp: false) == [.settings, .back])
    }

    /// The owner's notes n60, n61 (2026-11-19): the downloads' button "above the library icon instead of next to it, and
    /// stay between it and the settings and help when library is open": the place of the Library's glyph is the way back's.
    @Test func `the downloads' button is above the way back, under the gear, while there are downloads`() {
        #expect(SectionRail.foot(hasHelp: true, hasDownloads: true) == [.help, .settings, .downloads, .back])
        #expect(SectionRail.foot(hasHelp: false, hasDownloads: true) == [.settings, .downloads, .back])
        #expect(SectionRail.foot(hasHelp: true, hasDownloads: false) == [.help, .settings, .back])
    }
}
