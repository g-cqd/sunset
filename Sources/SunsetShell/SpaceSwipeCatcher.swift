import AppKit
import SwiftUI

/// Catches the two-finger swipe on the sidebar that changes Space: put behind the list, it reads the scroll events of
/// its window that are over it. A gesture that starts sideways is taken from the list (`SpaceSwipe` says what to do with
/// it); one that starts up or down goes to the list untouched. At the snap the trackpad taps once.
///
/// The gesture cannot be made by a test in the background: the numbers are tested (`SpaceSwipeTests`), this is not.
struct SpaceSwipeCatcher: NSViewRepresentable {
    let tabs: TabsModel
    let animation: Animation
    /// Where the Library is to swipe to, past the last Space on the sidebar's side; nil while it is not offered.
    let library: SpaceSwipe.LibrarySide?

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.tabs = tabs
        view.animation = animation
        view.library = library
    }

    static func dismantleNSView(_ view: CatcherView, coordinator: ()) {
        view.stop()
    }

    final class CatcherView: EventCatcherView {
        weak var tabs: TabsModel?
        var animation = Animation.default
        var library: SpaceSwipe.LibrarySide?

        /// Whether the event was this one's (the list does not get it then).
        override func take(_ event: NSEvent) -> Bool {
            // Not in the settings, whose lists and pages are not the Library's to leave by a swipe.
            guard let tabs, isOver(event),
                !(tabs.sections.isLibraryOpen && tabs.sections.library == .settings),
                SpaceSwipe.listens(
                    libraryOpen: tabs.sections.isLibraryOpen,
                    spaces: tabs.spaces?.spaces.count ?? 1,
                    library: library
                )
            else { return false }
            let ways = tabs.spaceWays(library: library)
            if event.phase.contains(.began) || event.phase.contains(.mayBegin) { tabs.spaceSwipe.begin() }
            // What the trackpad sends after the fingers left is not a swipe.
            let fingers = event.momentumPhase.isEmpty
            let step =
                fingers
                ? tabs.spaceSwipe.move(
                    dx: event.scrollingDeltaX,
                    dy: event.scrollingDeltaY,
                    width: bounds.width,
                    ways: ways
                )
                : tabs.spaceSwipe.move(dx: 0, dy: 0, width: bounds.width, ways: ways)
            defer {
                // Fingers up before enough was swiped: the list goes back to its place.
                if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                    _ = tabs.spaceSwipe.end()
                    tabs.settleSpaceList()
                }
            }
            switch step {
                case .scroll: return false
                case .consumed: return true
                case .follow:
                    // The tabs' list is hidden under the Library: nothing of it moves.
                    if !tabs.sections.isLibraryOpen { tabs.shift(spaceListTo: tabs.spaceSwipe.offset) }
                    return true
                case .snap(let direction):
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                    tabs.stepSpace(by: direction)
                    return true
                case .library:
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                    tabs.settleSpaceList()
                    tabs.sections.toggleLibrary()
                    return true
            }
        }
    }
}
