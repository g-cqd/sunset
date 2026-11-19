package import AppKit
package import SunsetRuntime

/// Keeps a window's three buttons (close, minimise, zoom) where Sunset wants them.
///
/// They stay AppKit's own, in its title bar: they are moved within it, never taken out. AppKit lays its title bar out again
/// whenever it sees fit (a resize, the window becoming key, full screen, the window shown while the screen is recorded) and
/// puts each button back at its own place; so the buttons, their bar and its container are watched, and every time one of
/// them moves the buttons are put back. Taken out of the title bar, as Sunset did before, AppKit took them back in and nothing
/// noticed: they stayed at its place, the top left, whatever side the sidebar was on (diary 2026-11-15). The way of the
/// Search browser by Office Commun (its `Lights.swift`, read for this; none of its code is here).
///
/// A button cannot be moved while it says that it moved: AppKit's `-[_NSThemeWidget setFrameOrigin:ignoreRentry:]` drops the
/// call. Each button was so put back while the next one said it had moved, and the last, the zoom button, never: a new title
/// left it at the top left (diary 2026-11-15-02). So a button that moves is put back again once AppKit is done: at once when
/// it is the title that changed (the window's title is watched), else on the run loop's next turn, before anything is drawn.
@MainActor
package final class WindowLights {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    package var runtime = Runtime.live

    /// Where the buttons go and whether they show.
    package struct Placement: Equatable, Sendable {
        /// From the window's edge to the near edge of the close button, in points.
        package var inset: Double
        /// From the window's top to the buttons' top; to their middle when `centred`.
        package var top: Double
        /// On the right, mirrored: the close button nearest the edge.
        package var fromRight: Bool
        package var centred: Bool
        package var visible: Bool

        package init(inset: Double, top: Double, fromRight: Bool, centred: Bool, visible: Bool) {
            self.inset = inset
            self.top = top
            self.fromRight = fromRight
            self.centred = centred
            self.visible = visible
        }
    }

    /// Nil: AppKit's own layout, which is then left alone.
    package var placement: Placement? {
        didSet {
            if placement != oldValue { place() }
        }
    }
    /// From one button's left edge to the next's: AppKit's own, read once from its first layout. Read at each pass it could be
    /// caught while AppKit was half way through moving them.
    package let spacing: Double
    /// How many times something had moved and the buttons were put back (for tests and probes).
    package private(set) var placements = 0
    /// The buttons have been moved at least once: going back to AppKit's layout needs its title bar made again.
    package private(set) var hasPlaced = false

    private weak var window: NSWindow?
    private var placing = false
    private var observers: [any NSObjectProtocol] = []
    private var watched: [ObjectIdentifier] = []
    private var viewObservers: [any NSObjectProtocol] = []
    private var titleObserver: NSKeyValueObservation?
    /// A pass is waiting for the run loop's next turn.
    private var pending = false
    private static let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
    /// Where a hidden button is parked: outside the window, with nothing to click.
    private static let parked = -200.0

    package init(window: NSWindow) {
        self.window = window
        let row = Self.types.prefix(2).compactMap { window.standardWindowButton($0) }
        let measured = row.count == 2 ? Double(row[1].frame.minX - row[0].frame.minX) : 0
        spacing = (16 ... 32).contains(measured) ? measured : Design.System.lightsPitch
        let names: [Notification.Name] = [
            NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification, NSWindow.didBecomeKeyNotification,
            NSWindow.didResignKeyNotification, NSWindow.didBecomeMainNotification,
            NSWindow.didExitFullScreenNotification, NSWindow.didChangeScreenNotification
        ]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: window, queue: nil) { [weak self] _ in
                MainActor.assumeIsolated { self?.place() }
            }
        }
        // Told when AppKit is done with a new title, its title bar tiled: every button can be moved then.
        titleObserver = window.observe(\.title) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.place() }
        }
    }

    isolated deinit {
        titleObserver?.invalidate()
        (observers + viewObservers).forEach { NotificationCenter.default.removeObserver($0) }
    }

    private var buttons: [NSButton] {
        Self.types.compactMap { window?.standardWindowButton($0) }
    }

    /// The buttons, their bar and its container are watched for any move: the surest sign that AppKit has just laid them out
    /// again. Watched anew when they are not the views watched before (AppKit makes its title bar again at times).
    private func watch(_ views: [NSView]) {
        let ids = views.map(ObjectIdentifier.init)
        guard ids != watched else { return }
        watched = ids
        viewObservers.forEach { NotificationCenter.default.removeObserver($0) }
        viewObservers = views.map { view in
            view.postsFrameChangedNotifications = true
            return NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: view,
                queue: nil
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.place()
                    // The view that says it moved may not be moved now: once more when AppKit is done.
                    self?.placeLater()
                }
            }
        }
    }

    /// Another pass on the run loop's next turn, which comes before the window is drawn; one however many ask.
    private func placeLater() {
        guard !pending else { return }
        pending = true
        RunLoop.main.perform(inModes: [.common]) { [weak self] in
            MainActor.assumeIsolated {
                self?.pending = false
                self?.place()
            }
        }
    }

    /// Puts the buttons where `placement` says, when they are not there. Cheap when nothing moved: three comparisons.
    package func place() {
        // Full screen keeps its title bar in a window of its own, laid out by macOS: it is left to it.
        guard !placing, let placement, let window, !window.styleMask.contains(.fullScreen) else { return }
        let buttons = self.buttons
        guard buttons.count == 3, let bar = buttons[0].superview, let container = bar.superview else { return }
        placing = true
        defer { placing = false }
        watch([container, bar] + buttons)
        var moved = false
        // A title bar tall enough for the buttons to sit as low as asked; never shorter than AppKit made it.
        let size = buttons[0].frame.size
        let top = placement.centred ? placement.top - size.height / 2 : placement.top
        let needed = top + size.height + max(top, 0)
        if container.frame.height < needed {
            var frame = container.frame
            frame.origin.y -= needed - frame.height
            frame.size.height = needed
            container.frame = frame
            moved = true
        }
        for (index, button) in buttons.enumerated() {
            let offset = Double(index) * spacing
            let x =
                placement.fromRight
                ? window.frame.width - placement.inset - size.width - offset : placement.inset + offset
            let inWindow = NSRect(
                x: x,
                y: window.frame.height - top - size.height,
                width: size.width,
                height: size.height
            )
            var origin = bar.convert(inWindow, from: nil).origin
            // Parked once its fade is over; at once when it has no layer to fade.
            if !placement.visible, Self.isFaded(button) { origin.x = Self.parked }
            if fade(button, visible: placement.visible, to: origin) { moved = true }
        }
        if moved {
            placements += 1
            hasPlaced = true
        }
    }

    /// Nothing of it shows: faded out, or with no layer to fade.
    private static func isFaded(_ button: NSButton) -> Bool {
        button.layer.map { $0.opacity == 0 } ?? true
    }

    /// The buttons are AppKit's to lay out again (`placement` is nil): shown, and counted as never moved.
    package func released() {
        hasPlaced = false
        for button in buttons { button.layer?.opacity = 1 }
    }

    /// Moves a button to `origin` and fades its layer in or out; whether anything changed. The layer's opacity is animated, not
    /// the view's `alphaValue` or `isHidden`: changing those made AppKit lay the buttons out again at its own spot. A button
    /// that fades out is parked outside the window when the fade is over.
    private func fade(_ button: NSButton, visible: Bool, to origin: NSPoint) -> Bool {
        var changed = false
        if visible || Self.isFaded(button), button.frame.origin != origin {
            button.setFrameOrigin(origin)
            changed = true
        }
        guard let layer = button.layer else { return changed }
        let target: Float = visible ? 1 : 0
        guard layer.opacity != target else { return changed }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = layer.presentation()?.opacity ?? layer.opacity
        animation.toValue = target
        animation.duration = 0.18
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "fade")
        layer.opacity = target
        if !visible {
            runtime.task { @MainActor [weak self, runtime] in
                await runtime.sleep(for: .milliseconds(200))
                self?.place()
            }
        }
        return true
    }
}
