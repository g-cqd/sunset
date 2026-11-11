import AppKit
import SunsetConfig
import SunsetShell

/// The few things SwiftUI's `App` does not say: this process is a regular app even when started as a bare executable, and it ends with its last window.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        SessionStore.shared.finish()
        return .terminateNow
    }

    func applicationDidResignActive(_ notification: Notification) { SessionStore.shared.saveNow() }

    /// The app ends with its last window, unless a kept entry is open and the setting keeps it running for it (R3).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        MainActor.assumeIsolated {
            !(AppConfiguration.shared.configuration.tabs.keepRunningForFavorites && AppFavorites.shared.hasOpenEntry)
        }
    }
}
