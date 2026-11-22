import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// With no Favorite, one space between the Pinned grid and the tabs, not the grid's and the Favorites' line's both.
@MainActor
@Suite("The room between the sidebar's sections")
struct SectionSeparatorRoomTests {
    @Test func `with no Favorite under the Pinned grid, the Favorites' line takes no room`() {
        #expect(SectionSeparator.height(visible: false, collapsed: true) == 0)
        #expect(SectionSeparator.height(visible: false, collapsed: false) == SectionSeparator.hiddenRoom)
        #expect(SectionSeparator.height(visible: true, collapsed: false) == SectionSeparator.room)
    }
}
