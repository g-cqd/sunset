import AppKit
import SunsetRuntime
import SunsetShellModel
import SwiftUI

/// Plays the welcome's opening (`WelcomeOpening`): the sun alone in a borderless panel over the screen, where the window
/// will keep it; then the real window, transparent at first, fades in where it stands while its content comes into focus
/// and the panel's sun fades. A click or a key ends it at once (HIG Motion: let people cancel motion); with Reduce
/// Motion on, the window shows at once.
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
        WelcomeOpeningAudio.play()
        // The key or click that ends it does only that.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { _ in
            end(cancelled: true)
            return nil
        }
        let start = Runtime.live.now()
        Runtime.live.task { @MainActor in
            await Runtime.live.sleep(for: .seconds(WelcomeOpening.windowPhase.start))
            guard window === shown else { return }
            shown.alphaValue = 0
            show(shown)
            // The window's opacity from the model each frame, the same curve as its content's focus and the sun's fade (a
            // Core Animation curve only came near it).
            while window === shown {
                let elapsed = Runtime.live.now().timeIntervalSince(start)
                guard elapsed < WelcomeOpening.duration else { break }
                shown.alphaValue = WelcomeOpening.at(elapsed, frame: .zero).windowOpacity
                await Runtime.live.sleep(for: .milliseconds(8))
            }
            end(cancelled: false)
        }
    }

    private static func show(_ shown: NSWindow) {
        shown.makeKeyAndOrderFront(nil)
        // Over what is in front, as the opening was (Sunset may not be the active app).
        shown.orderFrontRegardless()
    }

    /// The window alone, at once; once. When cancelled early, the score fades out smoothly; at the natural end, its
    /// diffused reverb tail finishes on its own.
    private static func end(cancelled: Bool) {
        guard let sun = panel, let shown = window else { return }
        panel = nil
        window = nil
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        clock?.finish()
        clock = nil
        if cancelled { WelcomeOpeningAudio.fadeOut() }
        if !shown.isVisible { show(shown) }
        shown.alphaValue = 1
        sun.orderOut(nil)
    }
}
