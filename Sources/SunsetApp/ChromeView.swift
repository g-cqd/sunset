import AppKit
import Foundation
import SunsetConfig
import SunsetHost
import SunsetShell

/// The view behind the terminal that acts on its window (see `WindowChrome`).
final class ChromeView: NSView {
    var settings = Configuration.Window() { didSet { if settings != oldValue { apply() } } }
    var look = WindowLook() { didSet { if look != oldValue { apply() } } }
    /// Where the traffic lights are, from the window's top left corner, and whether they show; nil: where `settings` says, shown.
    var lights: LightsPlacement? { didSet { if lights != oldValue { placeButtons() } } }
    var presentation = TabPresentation.windows { didSet { if presentation != oldValue { apply() } } }
    /// Told the window as soon as the view has one (the scene needs it for the sidebar and the tab registry).
    var attached: (NSWindow) -> Void = { _ in }
    /// Told how much of the window's top the title bar and the system tab bar cover (`contentLayoutRect`, KVO compliant), in points.
    var obscuredTop: (Double) -> Void = { _ in }
    private let backdrop = WindowBackdrop()
    /// SwiftUI sets the window's style again when the content around it changes; these notice and put ours back.
    private var styleObservations: [NSKeyValueObservation] = []
    private var applying = false
    /// Keeps the window's buttons where they are put, whatever AppKit does to its title bar (`WindowLights`).
    private var keeper: WindowLights?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        keeper = nil
        guard let window else { return }
        keeper = WindowLights(window: window)
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
        // Not with system tabs: SwiftUI asserts (BarAppearanceBridge.updatePlatformBar) when a window with a transparent title bar
        // closes in a tab group (crash reports 2026-11-13, t242/t243; its own close handler runs before any of ours).
        let transparent = hidden && !presentation.usesSystemTabbing
        if window.titlebarAppearsTransparent != transparent { window.titlebarAppearsTransparent = transparent }
        let visibility: NSWindow.TitleVisibility = hidden ? .hidden : .visible
        if window.titleVisibility != visibility { window.titleVisibility = visibility }
        // Locked scheme: the window (and with it the glass, the materials, the buttons) is dark whatever macOS is set to; nil follows the system.
        let appearance = look.scheme.nsAppearance
        if window.appearance?.name != appearance?.name { window.appearance = appearance }
        backdrop.apply(look, to: window)
        applyTabbing(to: window)
        placeButtons()
    }

    /// With no decorations the three system buttons are put where the sidebar or the tab bar wants them, and kept there
    /// (`WindowLights`: they stay in AppKit's title bar and are put back each time it lays them out again). Back to `native`,
    /// the title bar is made again by switching the `titled` style off and on, which gives the buttons their own places.
    private func placeButtons() {
        guard let window, let keeper else { return }
        if settings.decorations == .native {
            keeper.placement = nil
            if keeper.hasPlaced {
                keeper.released()
                window.styleMask.remove(.titled)
                window.styleMask.insert(.titled)
                if window.titlebarAppearsTransparent { window.titlebarAppearsTransparent = false }
                if window.titleVisibility != .visible { window.titleVisibility = .visible }
            }
            return
        }
        let wanted =
            lights
            ?? LightsPlacement(
                x: settings.trafficLightsX,
                y: settings.trafficLightsY,
                visible: true,
                side: settings.lightsSide.resolved(sidebar: .left)
            )
        keeper.placement = WindowLights.Placement(
            inset: wanted.x,
            top: wanted.y,
            fromRight: wanted.side == .right,
            centred: wanted.centred,
            visible: wanted.visible
        )
        // Asked again at each pass of the window's style: cheap when nothing moved.
        keeper.place()
    }
}
