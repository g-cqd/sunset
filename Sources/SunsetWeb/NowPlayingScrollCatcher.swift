import AppKit
import SunsetShell
import SunsetWebModel
import SwiftUI

/// Reads the scrolls over the Now Playing stack (roadmap 0114): one that goes up or down is the stack's, in cards
/// (`MediaStackScroll`); one that goes sideways is left to the sidebar (the swipe between Spaces).
///
/// A test in the background cannot scroll: the numbers are tested (`MediaStackTests`), this is not.
struct NowPlayingScrollCatcher: View {
    let scrolled: @MainActor (Int) -> Void
    @State private var scroll = Scroll()

    /// What the scroll has gone so far, kept across events.
    final class Scroll {
        var cards = MediaStackScroll(threshold: Design.NowPlaying.scrollStep)
    }

    var body: some View {
        EventCatcher(events: .scrollWheel) { event, view in
            guard (view as? EventCatcherView)?.isOver(event) == true,
                abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX)
            else { return false }
            // The momentum after the fingers lift moves nothing (n125: the stack snaps, it does not coast).
            guard event.momentumPhase.isEmpty else { return true }
            // A mouse wheel's click turns one card.
            if !event.hasPreciseScrollingDeltas {
                if event.scrollingDeltaY != 0 { scrolled(event.scrollingDeltaY > 0 ? -1 : 1) }
                return true
            }
            // Fingers up move the stack up: the next card comes to the front.
            let cards = scroll.cards.add(-event.scrollingDeltaY)
            if cards != 0 { scrolled(cards) }
            if event.phase == .ended || event.phase == .cancelled { scroll.cards.end() }
            return true
        }
    }
}
