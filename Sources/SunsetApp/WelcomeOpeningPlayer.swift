import AppKit
import SunsetRuntime
import SunsetShellModel
import SwiftUI

/// Plays the welcome's opening (roadmap 0084 G; `WelcomeOpening`): the sun alone in a borderless panel over the screen,
/// where the window will keep it; then the real window, transparent at first, fades in where it stands while its content
/// comes into focus and the panel's sun fades. A click or a key ends it at once (HIG Motion: let people cancel motion);
/// with Reduce Motion on, the window shows at once.
@MainActor enum WelcomeOpeningPlayer {
    private static var panel: NSPanel?
    private static var window: NSWindow?
    private static var monitor: Any?
    private static var clock: WelcomeOpeningClock?

    /// The opening on `screen` for `window`, whose content follows `clock`.
    static func play(on screen: NSScreen, for shown: NSWindow, clock: WelcomeOpeningClock) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return show(shown) }
        let frame = screen.frame
        let target = shown.frame
        let local = CGRect(
            x: target.minX - frame.minX,
            y: frame.maxY - target.maxY,
            width: target.width,
            height: target.height
        )
        let sun = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        sun.title = "Sunset Opening"
        sun.isOpaque = false
        sun.backgroundColor = .clear
        sun.hasShadow = false
        sun.ignoresMouseEvents = true
        sun.level = .statusBar
        sun.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        sun.contentView = NSHostingView(
            rootView: SunsetSkyView { time, _ in SunsetSkyFrame.opening(at: time, frame: local) }.ignoresSafeArea()
        )
        sun.orderFrontRegardless()
        panel = sun
        window = shown
        self.clock = clock
        clock.begin()
        // The key or click that ends it does only that.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { _ in
            end()
            return nil
        }
        Runtime.live.task { @MainActor in
            await Runtime.live.sleep(for: .seconds(WelcomeOpening.windowPhase.start))
            guard window === shown else { return }
            shown.alphaValue = 0
            show(shown)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = WelcomeOpening.windowPhase.length
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                shown.animator().alphaValue = 1
            } completionHandler: {
            }
            await Runtime.live.sleep(for: .seconds(WelcomeOpening.duration - WelcomeOpening.windowPhase.start))
            end()
        }
    }

    private static func show(_ shown: NSWindow) {
        shown.makeKeyAndOrderFront(nil)
        // Over what is in front, as the opening was (Sunset may not be the active app).
        shown.orderFrontRegardless()
    }

    /// The window alone, at once; once.
    private static func end() {
        guard let sun = panel, let shown = window else { return }
        panel = nil
        window = nil
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        clock?.finish()
        clock = nil
        if !shown.isVisible { show(shown) }
        shown.alphaValue = 1
        sun.orderOut(nil)
    }
}
