public import AppKit

/// A view that reads its window's events of a kind (`events`) while it is in one, and keeps those `take` says are its own
/// (the others go on as ever): the swipe between Spaces and the Now Playing stack (scrolls), an entry's page (⌘V of a
/// picture).
@MainActor
open class EventCatcherView: NSView {
    private var monitor: Any?

    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stop()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            // The monitor is called on the main thread, where events are.
            let taken = MainActor.assumeIsolated { self?.take(event) ?? false }
            return taken ? nil : event
        }
    }

    /// The events it reads: the scrolls, unless a subclass says otherwise.
    open var events: NSEvent.EventTypeMask {
        .scrollWheel
    }

    /// Stops reading them.
    public func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    /// Whether `event` is this view's: then nothing else gets it.
    open func take(_ event: NSEvent) -> Bool {
        false
    }

    /// Whether `event` is in this view's window, under this view.
    public func isOver(_ event: NSEvent) -> Bool {
        event.window === window && bounds.contains(convert(event.locationInWindow, from: nil))
    }
}
