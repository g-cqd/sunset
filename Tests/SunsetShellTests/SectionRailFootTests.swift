import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Help sits above Settings at the foot of the Library's bar.
@Suite("The Library's foot")
@MainActor
struct SectionRailFootTests {
    @Test func `Help is above the gear, the way back last`() {
        #expect(SectionRail.foot(hasHelp: true) == [.help, .settings, .back])
        #expect(SectionRail.foot(hasHelp: false) == [.settings, .back])
    }

    /// The downloads' button "above the library icon instead of next to it, and stay between it and the settings and help
    /// when library is open": the place of the Library's glyph is the way back's.
    @Test func `the downloads' button is above the way back, under the gear, while there are downloads`() {
        #expect(SectionRail.foot(hasHelp: true, hasDownloads: true) == [.help, .settings, .downloads, .back])
        #expect(SectionRail.foot(hasHelp: false, hasDownloads: true) == [.settings, .downloads, .back])
        #expect(SectionRail.foot(hasHelp: true, hasDownloads: false) == [.help, .settings, .back])
    }
}
