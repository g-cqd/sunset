import AppKit
import QuartzCore
import SunsetRuntime
import SunsetShellModel
import SwiftUI

/// Plays the welcome's opening (`WelcomeOpening`) in lockstep with `WelcomeOpeningAudio`: the sun alone in a
/// borderless panel over the screen, where the window will keep it; then the real window, transparent at first, fades
/// in where it stands while its content comes into focus and the panel's sun fades. A click or a key ends it at once
/// (HIG Motion: let people cancel motion); with Reduce Motion on, the window shows at once.
@MainActor enum WelcomeOpeningPlayer {
    private static var panel: NSPanel?
    private static var window: NSWindow?
    private static var monitor: Any?
    private static var clock: WelcomeOpeningClock?

    /// The opening on `screen` for `window`, whose content follows `clock`, in `preset`.
    static func play(on screen: NSScreen, for shown: NSWindow, clock: WelcomeOpeningClock, preset: SkyPreset = .sunset)
    {
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
        // Drive the sun shader from the shared clock so it stays locked to the audio engine and window fade.
        sun.contentView = NSHostingView(
            rootView: SunsetSkyView { _, _ in
                SunsetSkyFrame.opening(at: clock.elapsed(), frame: local, preset: preset)
            }
            .ignoresSafeArea()
        )
        // Start audio before anchoring the shared clock so engine warm-up and output latency stay aligned with t = 0.
        let audioLatency = WelcomeOpeningAudio.play()
        clock.begin(delay: audioLatency)
        sun.orderFrontRegardless()
        panel = sun
        window = shown
        self.clock = clock
        // The key or click that ends it does only that.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { _ in
            end(cancelled: true)
            return nil
        }
        Runtime.live.task { @MainActor in
            let waitForWindow = max(
                0,
                (clock.mediaStart ?? CACurrentMediaTime()) + WelcomeOpening.windowPhase.start - CACurrentMediaTime()
            )
            await Runtime.live.sleep(for: .seconds(waitForWindow))
            guard window === shown else { return }
            shown.alphaValue = 0
            show(shown)
            // The window's opacity from the model each frame, using the same shared clock as the sun and content focus.
            while window === shown {
                let elapsed = clock.elapsed()
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
