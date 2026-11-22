import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The Spaces are put in another order by dragging their icons at the foot of the sidebar.
@MainActor @Suite("Dragging a Space's icon")
struct SpacesDragTests {
    @Test func `a Space dragged over another's icon takes its place, and the others make room`() throws {
        let spaces = SpacesModel(makeFavorites: { FavoritesModel() })
        for _ in 0 ..< 3 { _ = spaces.add(from: nil) }
        let names = { spaces.spaces.map(\.space.id) }
        let first = names()
        let dragged = spaces.spaces[0].space.id
        spaces.drag(dragged, over: spaces.spaces[2].space.id)
        #expect(names() == [first[1], first[2], first[0], first[3]], "rightward: after the one it is over")
        spaces.drag(dragged, over: spaces.spaces[0].space.id)
        #expect(names() == first, "leftward: back in front")
        spaces.drag(dragged, over: dragged)
        #expect(names() == first, "over itself: nothing moves")
    }
}
