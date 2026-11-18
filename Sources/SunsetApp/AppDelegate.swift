import AppKit
import SunsetConfig
import SunsetDocuments
import SunsetShell
import SunsetWeb

/// The few things SwiftUI's `App` does not say: this process is a regular app even when started as a bare executable, and it ends with its last window.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Started for a test driven through accessibility (`Tools/axdrive`): it stays behind what the person is doing.
        if ProcessInfo.processInfo.environment["SUNSET_BACKGROUND"] != "1" { NSApp.activate() }
        MainActor.assumeIsolated {
            SystemRestoration.excludeEveryWindow()
            AppDownloads.start()
            AppWebNotifications.start()
            AppPageSleep.start()
            AppBlocking.start()
            SystemAuthorizations.shared.start()
            AppConfiguration.shared.applyScheme()
        }
    }

    /// Files opened with Sunset (Finder's Open With, a drop on its icon, `open -a`): each in a tab of the window in front;
    /// links to pages from other apps, Sunset being the Mac's browser (note n18): each a page in a tab of that window.
    func application(_ application: NSApplication, open urls: [URL]) {
        let incoming = IncomingLinks.split(urls)
        MainActor.assumeIsolated {
            if !incoming.files.isEmpty { AppActions.shared.open(files: incoming.files) }
            if !incoming.pages.isEmpty { AppActions.shared.open(pages: incoming.pages) }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { AppStorage.shared.close() }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        MainActor.assumeIsolated { QuitGate.shared.shouldTerminate() }
    }

    func applicationDidResignActive(_ notification: Notification) {
        SessionStore.shared.saveNow()
        // Another app came to the front: the documents that save themselves then do (`documents.saveOnFocusLoss`).
        MainActor.assumeIsolated { AppStorage.shared.openDocuments.focusLost() }
    }

    /// The app ends with its last window, unless a kept entry is open and the setting keeps it running for it (R3).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        MainActor.assumeIsolated {
            !(AppConfiguration.shared.configuration.tabs.keepRunningForFavorites && AppFavorites.hasOpenEntry)
        }
    }
}
