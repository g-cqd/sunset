import AppKit
import SunsetAppCore
import SunsetRuntime
import SunsetShell
import SunsetShellModel
import SwiftUI

/// The welcome's window: on the first launch after the sky's opening, and from Help ▸ Welcome to Sunset. Closing it in
/// any way marks it seen.
@MainActor final class WelcomeWindow: NSObject, NSWindowDelegate {
    static let shared = WelcomeWindow()
    private var window: NSWindow?

    /// The marker beside the configuration file that says it was shown.
    private static var marker: String {
        (AppConfiguration.shared.path as NSString).deletingLastPathComponent + "/welcome-seen"
    }

    /// Whether this launch is the first (`WelcomeGate`): the welcome opens, and the main window waits for it: it shows
    /// only once the welcome is passed. Decided once, before any scene: the configuration file is looked for before
    /// anything could write it.
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
    /// What the easter egg cleared, to put back when the welcome closes.
    private let clearing = ScreenClearing()

    /// The easter egg (Option on the Sunset menu: Watch the Sunset Again): Sunset's windows minimized and the other apps
    /// hidden, the sun's opening, and a welcome that says what was found; all put back when it closes.
    func watchAgain() {
        guard window == nil else { return open() }
        let mine = NSApp.windows.filter { $0.styleMask.contains(.miniaturizable) && $0.level == .normal }
        let others = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }
        clearing.clear(mine + others)
        // After the windows' own minimizing has played.
        Runtime.live.task { @MainActor in
            await Runtime.live.sleep(for: .milliseconds(700))
            self.open(withOpening: true, greeting: .again)
        }
    }

    /// At launch: opens it when this is the first launch, the main window after it.
    func openIfFirstLaunch() {
        guard Self.atLaunch else { return }
        holdsMainWindow = true
        open(withOpening: true)
    }

    /// Shows it; after the sky's opening when `withOpening`.
    func open(withOpening: Bool = false, greeting: WelcomeGreeting = .first) {
        if let window {
            return window.makeKeyAndOrderFront(nil)
        }
        let clock = WelcomeOpeningClock()
        // Time-of-day sky preset (n143): Dawn, Sunset, Twilight or Dusk for both the opening sun and the window.
        let preset = SkyPreset.at(Runtime.live.now())
        let made = SkyWindow.make(title: "Welcome to Sunset", size: Design.Welcome.size, showsClose: false) { made in
            WelcomeView(store: .shared, clock: clock, greeting: greeting, preset: preset) { [weak made] in
                made?.close()
            }
        }
        made.delegate = self
        if let screen = NSScreen.main { made.setFrameOrigin(Self.origin(on: screen)) }
        window = made
        guard withOpening, let screen = made.screen ?? NSScreen.main else { return made.makeKeyAndOrderFront(nil) }
        WelcomeOpeningPlayer.play(on: screen, for: made, clock: clock, preset: preset)
    }

    /// Where the window goes: the middle of the screen's visible part, both ways ("more centered vertically"; it was
    /// placed for its sun to be on the screen's centre, which put it high). The opening's sun is drawn where this window
    /// keeps it, wherever that is.
    static func origin(on screen: NSScreen) -> CGPoint {
        let visible = screen.visibleFrame
        return CGPoint(
            x: (visible.midX - Design.Welcome.size.width / 2).rounded(),
            // The optical centre, a little above the middle, as macOS centres a window ("a bit too low").
            y: (visible.midY - Design.Welcome.size.height / 2 + visible.height * Design.Welcome.opticalLift).rounded()
        )
    }

    func windowWillClose(_ notification: Notification) {
        WelcomeOpeningAudio.fadeOut()
        // The main window, held back, opens as the welcome goes (before it has: no moment without a window, when Sunset
        // would quit).
        clearing.restore()
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
