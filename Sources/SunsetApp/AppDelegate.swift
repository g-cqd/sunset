import AppKit

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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
