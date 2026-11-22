package import AppKit
package import SwiftUI

/// An `EventCatcherView` in a SwiftUI view: `take` is given each event of `events` in the window, with the view it was
/// caught by, and says whether it is kept. The Now Playing stack's scrolls, an entry's page's pasted picture.
package struct EventCatcher: NSViewRepresentable {
    let events: NSEvent.EventTypeMask
    let take: @MainActor (NSEvent, NSView) -> Bool

    package init(events: NSEvent.EventTypeMask, take: @escaping @MainActor (NSEvent, NSView) -> Bool) {
        self.events = events
        self.take = take
    }

    package func makeNSView(context: Context) -> ClosureView {
        let view = ClosureView()
        update(view)
        return view
    }

    package func updateNSView(_ view: ClosureView, context: Context) {
        update(view)
    }

    package static func dismantleNSView(_ view: ClosureView, coordinator: ()) {
        view.stop()
    }

    private func update(_ view: ClosureView) {
        view.kinds = events
        view.taking = take
    }

    package final class ClosureView: EventCatcherView {
        var kinds: NSEvent.EventTypeMask = .scrollWheel
        var taking: @MainActor (NSEvent, NSView) -> Bool = { _, _ in false }

        override package var events: NSEvent.EventTypeMask {
            kinds
        }

        override package func take(_ event: NSEvent) -> Bool {
            taking(event, self)
        }
    }
}
