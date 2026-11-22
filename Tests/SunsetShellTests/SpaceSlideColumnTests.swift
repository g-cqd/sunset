import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Sliding between Spaces: the neighbour's tabs were drawn over this Space's tabs, below this Space's Pinned grid and
/// Favorites, and jumped to the top when the slide ended; the sides' fade came and went in one frame.
@MainActor @Suite("The neighbour's list while sliding between Spaces")
struct SpaceSlideColumnTests {
    @Test
    func `the neighbour's list is its own column: its tabs follow its own parts, a part both show keeps its place`() {
        var beside = SpaceSlide.Beside(tabs: TabsModel(), isNext: true)
        #expect(beside.column == [.own(.pinned), .own(.favorites), .own(.today)])
        beside.sharesPinned = true
        #expect(beside.column == [.kept(.pinned), .own(.favorites), .own(.today)])
        beside.sharesFavorites = true
        #expect(beside.column == [.kept(.pinned), .kept(.favorites), .own(.today)])
    }
}
