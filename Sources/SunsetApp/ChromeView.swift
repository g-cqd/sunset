import AppKit
import Foundation
import SunsetConfig
import SunsetHost

/// The view behind the terminal that acts on its window (see `WindowChrome`).
final class ChromeView: NSView {
    var settings = Configuration.Window() { didSet { if settings != oldValue { apply() } } }
    var look = WindowLook() { didSet { if look != oldValue { apply() } } }
    var presentation = TabPresentation.windows { didSet { if presentation != oldValue { apply() } } }
    /// Told the window as soon as the view has one (the scene needs it for the sidebar and the tab registry).
    var attached: (NSWindow) -> Void = { _ in }
    /// Told how much of the window's top the title bar and the system tab bar cover (`contentLayoutRect`, KVO compliant), in points.
    var obscuredTop: (Double) -> Void = { _ in }
    private let backdrop = WindowBackdrop()
    private var observers: [any NSObjectProtocol] = []
    /// SwiftUI sets the window's style again when the content around it changes; these notice and put ours back.
    private var styleObservations: [NSKeyValueObservation] = []
    private var applying = false
    /// The buttons have been taken out of the title bar (and have to be given back by rebuilding it).
    private var movedButtons = false
    private var spacing: Double?
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
            window.observe(\.contentLayoutRect, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.reportObscured() }
            },
            window.observe(\.styleMask) { [weak self] _, _ in MainActor.assumeIsolated { self?.apply() } }
        ]
        attached(window)
        apply()
        reportObscured()
    }

    /// SwiftUI puts the window's style back (the title shows again) when the content around us changes: asserted again on every layout, which is cheap
    /// because each assignment is skipped when the window already has the value.
    override func layout() {
        super.layout()
        apply()
    }

    private func reportObscured() {
        guard let window, let content = window.contentView else { return }
        let covered = max(0, content.frame.height - window.contentLayoutRect.maxY)
        obscuredTop(Double(covered))
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
        backdrop.apply(look, to: window)
        applyTabbing(to: window)
        placeButtons()
    }

    /// With no decorations the three system buttons leave the title bar and live in the window's frame view, above the content, so that they can be put
    /// anywhere in the window (inside the title bar they could only move within its strip). They keep their targets and actions, so close, minimise and zoom
    /// still work. Back to `native`, the pieces AppKit built for the old title bar are not worth reassembling (it drops its container when the style changes):
    /// the window's title bar is made again by switching the `titled` style off and on, which gives it new buttons in their place.
    private func placeButtons() {
        guard let window, let frame = window.contentView?.superview else { return }
        if settings.decorations == .native {
            if movedButtons {
                movedButtons = false
                window.styleMask.remove(.titled)
                window.styleMask.insert(.titled)
                if window.titlebarAppearsTransparent { window.titlebarAppearsTransparent = false }
                if window.titleVisibility != .visible { window.titleVisibility = .visible }
            }
            return
        }
        let buttons = Self.buttons.compactMap { type in window.standardWindowButton(type) }
        guard buttons.count == 3 else { return }
        if spacing == nil { spacing = buttons[1].frame.origin.x - buttons[0].frame.origin.x }
        for (index, button) in buttons.enumerated() {
            if button.superview !== frame {
                button.removeFromSuperview()
                frame.addSubview(button, positioned: .above, relativeTo: nil)
                movedButtons = true
            }
            // From the window's top left corner; the frame view is not flipped, and the buttons stay at the top left when the window is resized.
            button.autoresizingMask = [.maxXMargin, .minYMargin]
            let x = settings.trafficLightsX + Double(index) * (spacing ?? 23)
            let y = frame.bounds.height - settings.trafficLightsY - button.frame.height
            button.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}
