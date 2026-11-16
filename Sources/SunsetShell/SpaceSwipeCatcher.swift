import AppKit
import SwiftUI

/// Catches the two-finger swipe on the sidebar that changes Space (roadmap 0021 step S-b): put behind the list, it reads
/// the scroll events of its window that are over it. A gesture that starts sideways is taken from the list (`SpaceSwipe`
/// says what to do with it); one that starts up or down goes to the list untouched. At the snap the trackpad taps once.
///
/// The gesture cannot be made by a test in the background: the numbers are tested (`SpaceSwipeTests`), this is not.
struct SpaceSwipeCatcher: NSViewRepresentable {
    let tabs: TabsModel
    let animation: Animation

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.tabs = tabs
        view.animation = animation
        return view
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.tabs = tabs
        view.animation = animation
    }

    static func dismantleNSView(_ view: CatcherView, coordinator: ()) { view.stop() }

    final class CatcherView: NSView {
        weak var tabs: TabsModel?
        var animation = Animation.default
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stop()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                // The monitor is called on the main thread, where events are.
                let taken = MainActor.assumeIsolated { self?.take(event) ?? false }
                return taken ? nil : event
            }
        }

        func stop() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        /// Whether the event was this one's (the list does not get it then).
        private func take(_ event: NSEvent) -> Bool {
            guard let tabs, let spaces = tabs.spaces, spaces.spaces.count > 1, event.window === window,
                bounds.contains(convert(event.locationInWindow, from: nil))
            else { return false }
            if event.phase.contains(.began) || event.phase.contains(.mayBegin) { tabs.spaceSwipe.begin() }
            // What the trackpad sends after the fingers left is not a swipe.
            let fingers = event.momentumPhase.isEmpty
            let step =
                fingers
                ? tabs.spaceSwipe.move(
                    dx: event.scrollingDeltaX,
                    dy: event.scrollingDeltaY,
                    width: bounds.width,
                    canGo: tabs.spaceNeighbours
                )
                : tabs.spaceSwipe.move(dx: 0, dy: 0, width: bounds.width, canGo: tabs.spaceNeighbours)
            if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                withAnimation(animation) { _ = tabs.spaceSwipe.end() }
            }
            switch step {
                case .scroll: return false
                case .follow, .consumed: return true
                case .snap(let direction):
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                    withAnimation(animation) { tabs.stepSpace(by: direction) }
                    return true
            }
        }
    }
}
