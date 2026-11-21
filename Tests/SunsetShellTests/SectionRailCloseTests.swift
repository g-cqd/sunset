import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner, 2026-11-17: the Library's way back "should point at the closing edge at all time, left when sidebar is on the
/// left, and right when sidebar is on the right […] the arrow pointing at a bar".
@Suite("The Library's way back")
@MainActor
struct SectionRailCloseTests {
    @Test func `it points at the window's edge the sidebar is on, at a bar`() {
        #expect(SectionRail.closeSymbol(leading: true) == "arrow.left.to.line")
        #expect(SectionRail.closeSymbol(leading: false) == "arrow.right.to.line")
    }
}
