import AppKit
import SunsetAppCore
import SunsetShell
import SunsetShellModel
import SwiftUI

/// The welcome's window (roadmap 0111 H; the owner's note n75): on the first launch after the sky's opening, and from
/// Help ▸ Welcome to Sunset. Closing it in any way marks it seen.
@MainActor final class WelcomeWindow: NSObject, NSWindowDelegate {
    static let shared = WelcomeWindow()
    private var window: NSWindow?

    /// The marker beside the configuration file that says it was shown.
    private static var marker: String {
        (AppConfiguration.shared.path as NSString).deletingLastPathComponent + "/welcome-seen"
    }

    /// Whether this launch is the first (`WelcomeGate`): the welcome opens, and the main window waits for it (the owner,
    /// 2026-11-21: "the main window of sunset should not show before onboarding is passed"). Decided once, before any
    /// scene: the configuration file is looked for before anything could write it.
    static let atLaunch: Bool = {
        let environment = ProcessInfo.processInfo.environment
        let path = MainActor.assumeIsolated { AppConfiguration.shared.path }
        let marker = (path as NSString).deletingLastPathComponent + "/welcome-seen"
        return WelcomeGate.opensByItself(
            configurationExisted: FileManager.default.fileExists(atPath: path),
            seen: FileManager.default.fileExists(atPath: marker),
            background: environment["SUNSET_BACKGROUND"] == "1",
            asked: environment["SUNSET_WELCOME"] == "1"
        )
    }()

    /// Whether the main window is held back until the welcome closes.
    private var holdsMainWindow = false

    /// At launch: opens it when this is the first launch, the main window after it.
    func openIfFirstLaunch() {
        guard Self.atLaunch else { return }
        holdsMainWindow = true
        open(withOpening: true)
    }

    /// Shows it; after the sky's opening when `withOpening`.
    func open(withOpening: Bool = false) {
        if let window {
            return window.makeKeyAndOrderFront(nil)
        }
        let made = NSWindow(
            contentRect: CGRect(origin: .zero, size: Design.Welcome.size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        made.title = "Welcome to Sunset"
        made.titlebarAppearsTransparent = true
        made.titleVisibility = .hidden
        made.isReleasedWhenClosed = false
        made.isMovableByWindowBackground = true
        made.delegate = self
        let clock = WelcomeOpeningClock()
        let hosting = NSHostingView(
            rootView: WelcomeView(store: .shared, clock: clock) { [weak made] in made?.close() }
        )
        // The sky to every edge: no room kept for the title bar (seen as a dark strip at the bottom).
        hosting.safeAreaRegions = []
        made.contentView = hosting
        made.setContentSize(Design.Welcome.size)
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            made.standardWindowButton(button)?.isHidden = true
        }
        if let screen = NSScreen.main { made.setFrameOrigin(Self.origin(on: screen)) }
        window = made
        guard withOpening, let screen = made.screen ?? NSScreen.main else { return made.makeKeyAndOrderFront(nil) }
        WelcomeOpeningPlayer.play(on: screen, for: made, clock: clock)
    }

    /// Where the window goes: its sun on the screen's centre, where the opening's glow appears; within the visible frame.
    static func origin(on screen: NSScreen) -> CGPoint {
        let centre = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        let top = centre.y + Design.Welcome.size.height * WelcomeOpening.sunHeight
        let visible = screen.visibleFrame
        let y = min(max(top - Design.Welcome.size.height, visible.minY), visible.maxY - Design.Welcome.size.height)
        return CGPoint(x: centre.x - Design.Welcome.size.width / 2, y: y)
    }

    func windowWillClose(_ notification: Notification) {
        // The main window, held back, opens as the welcome goes (before it has: no moment without a window, when Sunset
        // would quit).
        if holdsMainWindow {
            holdsMainWindow = false
            AppActions.shared.openTerminalWindow()
        }
        let folder = (Self.marker as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: Self.marker, contents: Data())
        window = nil
    }
}
