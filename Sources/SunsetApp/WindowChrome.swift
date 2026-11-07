import AppKit
import SunsetConfig
import SwiftUI

/// Gives the window the look the configuration asks for: with `decorations: none` the content fills the window under a transparent title bar with no title, and
/// the traffic lights stay, moved to where `trafficLights` says (within the title bar's own area: the system lays them out in it); with `native` the system's
/// title bar. It sits behind the terminal as a view of its own size and acts on the window it is in.
struct WindowChrome: NSViewRepresentable {
    var settings: Configuration.Window

    func makeNSView(context: Context) -> ChromeView { ChromeView() }

    func updateNSView(_ view: ChromeView, context: Context) { view.settings = settings }
}

final class ChromeView: NSView {
    var settings = Configuration.Window() { didSet { if settings != oldValue { apply() } } }
    private var observers: [any NSObjectProtocol] = []
    /// SwiftUI sets the window's style again when the content around it changes; these notice and put ours back.
    private var styleObservations: [NSKeyValueObservation] = []
    private var applying = false
    /// Where the three buttons were before we moved them, to put them back for `native`.
    private var originals: [NSWindow.ButtonType: NSPoint] = [:]
    private static let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
        guard let window else { return }
        // The system lays the buttons out again on these: put ours back each time.
        let names: [Notification.Name] = [
            NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification, NSWindow.didBecomeKeyNotification,
            NSWindow.didResignKeyNotification, NSWindow.didExitFullScreenNotification,
            NSWindow.didChangeScreenNotification
        ]
        for name in names {
            observers.append(
                NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.placeButtons() }
                }
            )
        }
        styleObservations = [
            window.observe(\.titleVisibility) { [weak self] _, _ in MainActor.assumeIsolated { self?.apply() } },
            window.observe(\.titlebarAppearsTransparent) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.apply() }
            },
            window.observe(\.styleMask) { [weak self] _, _ in MainActor.assumeIsolated { self?.apply() } }
        ]
        apply()
    }

    /// SwiftUI puts the window's style back (the title shows again) when the content around us changes: asserted again on every layout, which is cheap
    /// because each assignment is skipped when the window already has the value.
    override func layout() {
        super.layout()
        apply()
    }

    isolated deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }

    private func apply() {
        guard let window, !applying else { return }
        applying = true
        defer { applying = false }
        let hidden = settings.decorations == .none
        if hidden {
            window.styleMask.insert(.fullSizeContentView)
        } else {
            window.styleMask.remove(.fullSizeContentView)
        }
        if window.titlebarAppearsTransparent != hidden { window.titlebarAppearsTransparent = hidden }
        let visibility: NSWindow.TitleVisibility = hidden ? .hidden : .visible
        if window.titleVisibility != visibility { window.titleVisibility = visibility }
        placeButtons()
    }

    private func placeButtons() {
        guard let window else { return }
        let buttons = Self.buttons.compactMap { type in window.standardWindowButton(type).map { (type, $0) } }
        for (type, button) in buttons where originals[type] == nil { originals[type] = button.frame.origin }
        for (index, (type, button)) in buttons.enumerated() {
            guard let container = button.superview else { continue }
            if settings.decorations == .native {
                if let origin = originals[type] { button.setFrameOrigin(origin) }
                continue
            }
            // From the window's top left corner; the title bar's view is not flipped.
            let spacing = (originals[.miniaturizeButton]?.x ?? 0) - (originals[.closeButton]?.x ?? 0)
            let x = settings.trafficLightsX + Double(index) * spacing
            let y = container.frame.height - settings.trafficLightsY - button.frame.height
            button.setFrameOrigin(NSPoint(x: x, y: max(y, 0)))
        }
    }
}
