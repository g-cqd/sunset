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
}
