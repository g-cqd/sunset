public import AppKit

/// A view that reads its window's scroll events while it is in one, and keeps those `take` says are its own (the others
/// go on to what is under the pointer). Subclassed by what catches a gesture over a part of the sidebar: the swipe between
/// Spaces, the Now Playing stack.
@MainActor
open class ScrollCatcherView: NSView {
    private var monitor: Any?

    override open func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stop()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            // The monitor is called on the main thread, where events are.
            let taken = MainActor.assumeIsolated { self?.take(event) ?? false }
            return taken ? nil : event
        }
    }

    /// Stops reading the scrolls.
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
