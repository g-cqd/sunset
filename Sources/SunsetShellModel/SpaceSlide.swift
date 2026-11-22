/// The sidebar's list on its way from one Space to another ("we should still see the space we're swiping away, it
/// should still exist until the end of the snapping"). While the list is off its place the neighbour's list is drawn
/// beside it; the window changes Space when the slide has ended, not before.
package struct SpaceSlide {
    /// The neighbour's list, as a window that only looks at that Space (it is not among its viewers).
    package struct Beside {
        package let tabs: TabsModel
        /// It is the next Space: its list is to the right of this one.
        package let isNext: Bool
        /// Its Pinned grid is this window's (the same profile): the grid stays still while the rest slides.
        package var sharesPinned = false
        /// Its Favorites are this window's (the profile's, `spaces.favorites`): they stay still too.
        package var sharesFavorites = false

        /// The neighbour's list as a column of its own, from the top: a part both Spaces show keeps its place, empty,
        /// and stays still in this list; the others are the neighbour's, so its tabs follow its own Pinned grid and
        /// Favorites, at the top when it has none, as they will be once the slide has ended.
        package var column: [ColumnPart] {
            [SidebarPart.pinned, .favorites, .today].map { shares($0) ? .kept($0) : .own($0) }
        }

        /// Whether a part of the list is the same on both sides, and stays still.
        package func shares(_ part: SidebarPart) -> Bool {
            switch part {
                case .pinned: sharesPinned
                case .favorites: sharesFavorites
                case .today: false
            }
        }
    }

    /// A part of the neighbour's column: its own, or the place of one this list shows for both.
    package enum ColumnPart: Hashable {
        case own(SidebarPart)
        case kept(SidebarPart)
    }

    /// The list is cut and faded at the sidebar's sides (`LateralFade`): from the first move, until an animation of its own
    /// after the slide has ended (it came and went in one frame).
    package var masks = false
    /// Where the list is drawn, in points from its place (negative: towards the next Space).
    package var shift = 0.0
    package var beside: Beside?
    /// The sidebar's width, and how long its rows take to move (eased in and out): set by the sidebar while it is on screen.
    /// Without them there is nothing to slide, and a Space is gone to at once.
    package var width = 0.0
    package var duration: Double?
    /// A slide to another Space is under way: nothing else moves the list until it has ended.
    package var isRunning = false

    package init() {}

    /// Makes a change taking `duration` seconds, then calls what follows it.
    package typealias Runner = @MainActor (Double, @escaping () -> Void, @escaping () -> Void) -> Void
    /// At once: the model's own, before a sidebar gives its animated one (`SpaceSlide.animated`), and a test's.
    @MainActor package static let atOnce: Runner = { _, change, completion in
        change()
        completion()
    }
}
