import AppKit
import SunsetShell
import SunsetWebModel
import SwiftUI

/// Reads the scrolls over the Now Playing stack (roadmap 0114): one that goes up or down is the stack's, in cards
/// (`MediaStackScroll`); one that goes sideways is left to the sidebar (the swipe between Spaces).
///
/// A test in the background cannot scroll: the numbers are tested (`MediaStackTests`), this is not.
struct NowPlayingScrollCatcher: NSViewRepresentable {
    let scrolled: @MainActor (Int) -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.scrolled = scrolled
        return view
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.scrolled = scrolled
    }

    static func dismantleNSView(_ view: CatcherView, coordinator: ()) {
        view.stop()
    }

    final class CatcherView: ScrollCatcherView {
        var scrolled: @MainActor (Int) -> Void = { _ in }
        private var scroll = MediaStackScroll(threshold: Design.NowPlaying.scrollStep)

        override func take(_ event: NSEvent) -> Bool {
            guard isOver(event), abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) else { return false }
            // Fingers up move the stack up: the next card comes to the front.
            let cards = scroll.add(-event.scrollingDeltaY)
            if cards != 0 { scrolled(cards) }
            if event.phase == .ended || event.phase == .cancelled { scroll.end() }
            return true
        }
    }
}
