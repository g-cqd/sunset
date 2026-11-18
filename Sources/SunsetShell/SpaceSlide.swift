package import SwiftUI

/// The sidebar's list on its way from one Space to another (roadmap 0021; the owner's note n79: "we should still see the
/// space we're swiping away, it should still exist until the end of the snapping"). While the list is off its place the
/// neighbour's list is drawn beside it; the window changes Space when the slide has ended, not before.
package struct SpaceSlide {
    /// The neighbour's list, as a window that only looks at that Space (it is not among its viewers).
    package struct Beside {
        package let tabs: TabsModel
        /// It is the next Space: its list is to the right of this one.
        package let isNext: Bool
        /// Its Pinned grid is this window's (the same profile): the grid stays still while the rest slides (roadmap 0044 A).
        package var sharesPinned = false
        /// Its Favorites are this window's (the profile's, `spaces.favorites`): they stay still too (roadmap 0044 E).
        package var sharesFavorites = false

        /// Whether a part of the list is the same on both sides, and stays still.
        func shares(_ part: TabSidebar.Part) -> Bool {
            switch part {
                case .pinned: sharesPinned
                case .favorites: sharesFavorites
                case .today: false
            }
        }
    }

    /// Where the list is drawn, in points from its place (negative: towards the next Space).
    package var shift = 0.0
    package var beside: Beside?
    /// The sidebar's width, and the animation its rows use: set by the sidebar while it is on screen. Without them
    /// there is nothing to slide, and a Space is gone to at once.
    package var width = 0.0
    package var animation: Animation?
    /// A slide to another Space is under way: nothing else moves the list until it has ended.
    package var isRunning = false

    package init() {}

    /// Makes a change with an animation, then calls what follows it.
    package typealias Runner = @MainActor (Animation, @escaping () -> Void, @escaping () -> Void) -> Void
    @MainActor package static let animated: Runner = { animation, change, completion in
        withAnimation(animation, change, completion: completion)
    }
}
