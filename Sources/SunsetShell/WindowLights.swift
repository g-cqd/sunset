package import AppKit
package import SunsetRuntime

/// Keeps a window's three buttons (close, minimise, zoom) where Sunset wants them, including during a macOS screen-sharing
/// session where AppKit attaches a 66×20 `NSLocalWindowSharingWindow` pill anchored at `(closeButton.minX - 3, closeButton.minY - 3)`.
///
/// While `hasActiveWindowSharingSession` (or a sharing child window) is active:
/// - hidden buttons (floating sidebar collapsed) are NOT parked at `-200`, keeping the sharing pill inside the window;
/// - right-side buttons keep left-to-right order (`close` at the inner start of the 3-button slot instead of the outer edge)
///   and clamp `inset` and `top` by the pill's 3 pt overhang (`minSharingMargin` = 10 pt) so the 66×20 pill stays cleanly
///   inside the window bounds in docked, floating, and collapsed states.
@MainActor
package final class WindowLights {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
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
    /// Override for tests when simulating a screen-sharing session without private window-server state; nil queries the window.
    package var sharingOverride: Bool? {
        didSet {
            if sharingOverride != oldValue { place() }
        }
    }
    /// From one button's left edge to the next's: AppKit's own, read once from its first layout.
    package let spacing: Double
    /// How many times something had moved and the buttons were put back (for tests and probes).
    package private(set) var placements = 0
    /// The buttons have been moved at least once: going back to AppKit's layout needs its title bar made again.
    package private(set) var hasPlaced = false

    weak var window: NSWindow?
    private var placing = false
    private var observers: [any NSObjectProtocol] = []
    private var watched: [ObjectIdentifier] = []
    private var viewObservers: [any NSObjectProtocol] = []
    private var titleObserver: NSKeyValueObservation?
    var sharingContextToken: UnsafeMutableRawPointer?
    /// A pass is waiting for the run loop's next turn.
    private var pending = false
    private static let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
    /// Where a hidden button is parked when not sharing: outside the window, with nothing to click.
    private static let parked = -200.0
    /// `NSLocalWindowSharingWindow` is 66×20 pt, extending 3 pt past `closeButton`'s left and top edges; 10 pt keeps ≥7 pt margin.
    private static let minSharingMargin = 10.0
    private static let sharingPillWidth = 66.0

    package init(window: NSWindow) {
        self.window = window
        let row = Self.types.prefix(2).compactMap { window.standardWindowButton($0) }
        let measured = row.count == 2 ? Double(row[1].frame.minX - row[0].frame.minX) : 0
        spacing = (16 ... 32).contains(measured) ? measured : Design.System.lightsPitch
        // Watch both child-window additions/removals (AppKit attaches `NSLocalWindowSharingWindow` on screen-share)
        // and any window-level appearance/occlusion updates so `place()` adapts immediately when sharing begins or ends.
        let names: [Notification.Name] = [
            NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification, NSWindow.didBecomeKeyNotification,
            NSWindow.didResignKeyNotification, NSWindow.didBecomeMainNotification,
            NSWindow.didExitFullScreenNotification, NSWindow.didChangeScreenNotification,
            NSWindow.didChangeOcclusionStateNotification
        ]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: window, queue: nil) { [weak self] _ in
                MainActor.assumeIsolated { self?.place() }
            }
        }
        titleObserver = window.observe(\.title) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.place() }
        }
        observeSharing(of: window)
    }

    isolated deinit {
        titleObserver?.invalidate()
        stopObservingSharing()
        (observers + viewObservers).forEach { NotificationCenter.default.removeObserver($0) }
    }

    private var buttons: [NSButton] {
        Self.types.compactMap { window?.standardWindowButton($0) }
    }

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
                    self?.placeLater()
                }
            }
        }
    }

    func placeLater() {
        guard !pending else { return }
        pending = true
        RunLoop.main.perform(inModes: [.common]) { [weak self] in
            MainActor.assumeIsolated {
                self?.pending = false
                self?.place()
            }
        }
    }

    /// Puts the buttons where `placement` says, keeping macOS's 66×20 sharing pill inside the window when shared.
    package func place() {
        guard !placing, let placement, let window, !window.styleMask.contains(.fullScreen) else { return }
        let buttons = self.buttons
        guard buttons.count == 3, let bar = buttons[0].superview, let container = bar.superview else { return }
        placing = true
        defer { placing = false }
        watch([container, bar] + buttons)
        var moved = false
        let sharing = isSharingWindow
        let effectiveVisible = placement.visible || sharing
        let size = buttons[0].frame.size
        let rawTop = placement.centred ? placement.top - size.height / 2 : placement.top
        let top = sharing ? max(rawTop, Self.minSharingMargin) : rawTop
        let inset = sharing ? max(placement.inset, Self.minSharingMargin) : placement.inset
        let needed = top + size.height + max(top, 0)
        if container.frame.height < needed {
            var frame = container.frame
            frame.origin.y -= needed - frame.height
            frame.size.height = needed
            container.frame = frame
            moved = true
        }
        // When sharing on the right side, `NSLocalWindowSharingWindow` extends 63 pt to the right of `closeButton.minX`
        // (total pill width 66 pt, starting at `closeButton.minX - 3`). Placing `closeButton` at the inner edge of the
        // 3-button group (`2 * spacing` in from the right, clamped so `closeX + 63 <= width - minSharingMargin`) keeps
        // the entire sharing pill inside the window!
        let rightSpan = max(2 * spacing + size.width, Self.sharingPillWidth - 3)
        for (index, button) in buttons.enumerated() {
            let offset = Double(index) * spacing
            let x: Double
            if placement.fromRight {
                x =
                    sharing
                    ? max(Self.minSharingMargin, window.frame.width - inset - rightSpan) + offset
                    : window.frame.width - inset - size.width - offset
            } else {
                x = inset + offset
            }
            let inWindow = NSRect(
                x: x,
                y: window.frame.height - top - size.height,
                width: size.width,
                height: size.height
            )
            var origin = bar.convert(inWindow, from: nil).origin
            if !effectiveVisible, Self.isFaded(button) { origin.x = Self.parked }
            if fade(button, visible: effectiveVisible, to: origin) { moved = true }
        }
        if moved {
            placements += 1
            hasPlaced = true
        }
    }

    private static func isFaded(_ button: NSButton) -> Bool {
        button.layer.map { $0.opacity == 0 } ?? true
    }

    package func released() {
        hasPlaced = false
        for button in buttons { button.layer?.opacity = 1 }
    }

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
