import AppKit
import SunsetAppCore
import SunsetConfig
import SunsetCredentials
import SunsetDocuments
import SunsetRuntime
import SunsetShell
import SunsetStorage
import SunsetWeb

/// The few things SwiftUI's `App` does not say: this process is a regular app even when started as a bare executable, and it ends with its last window.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Each profile's extensions, from its folder, before any page is made.
        ExtensionHosts.shared.root = URL(filePath: StoragePlaces.current.extensions)
        AppExtensionWindows.start()
        AppExtensionTabs.start()
        ExtensionHosts.shared.installFromStore = { link, profile in
            AppActions.shared.install(from: link, profile: profile)
        }
        ExtensionHosts.shared.installPackage = { address, profile in
            AppActions.shared.installPackage(at: address, profile: profile)
        }
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Started for a test driven through accessibility (`Tools/axdrive`): it stays behind what the person is doing.
        if ProcessInfo.processInfo.environment["SUNSET_BACKGROUND"] != "1" { NSApp.activate() }
        WebKitFolders.tightenOwn()
        // Sites' caches out of backups: a walk of WebKit's folder, kept off the launch's way.
        Runtime.live.detached(priority: .utility) { WebKitFolders.excludeOwnCaches() }
        MainActor.assumeIsolated {
            SystemRestoration.excludeEveryWindow()
            AppDownloads.start()
            AppWebNotifications.start()
            AppPageSleep.start()
            AppBlocking.start()
            AppVaultLocking.start()
            NowPlaying.shared.goThere = { AppWebNotifications.shared.reveal($0) }
            AppPasswordFill.start()
            LongPressMenus.start()
            SystemAuthorizations.shared.start()
            AppConfiguration.shared.applyScheme()
            AppConfiguration.shared.applyIcon()
            AppConfiguration.shared.watchIconDay()
            WelcomeWindow.shared.openIfFirstLaunch()
            if !WelcomeWindow.atLaunch { AppEngineFreshness.tellIfBehind() }
            AppUpdates.start()
        }
    }

    /// Files opened with Sunset (Finder's Open With, a drop on its icon, `open -a`): each in a tab of the window in front;
    /// links to pages from other apps, Sunset being the Mac's browser: each a page in a tab of that window.
    func application(_ application: NSApplication, open urls: [URL]) {
        let incoming = IncomingLinks.split(urls)
        MainActor.assumeIsolated {
            if !incoming.files.isEmpty { AppActions.shared.open(files: incoming.files) }
            if !incoming.pages.isEmpty { AppActions.shared.open(pages: incoming.pages) }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated {
            AppVaultLocking.lockAll(.quit)
            SunsetStore.shared.close()
            AppUpdates.shared.installAtQuit()
        }
        WebKitFolders.tightenOwn()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        MainActor.assumeIsolated { QuitGate.shared.shouldTerminate() }
    }

    func applicationDidResignActive(_ notification: Notification) {
        SessionStore.shared.saveNow()
        // Another app came to the front: the documents that save themselves then do (`documents.saveOnFocusLoss`), and
        // the vault's entries being edited are kept (n138).
        MainActor.assumeIsolated {
            SunsetStore.shared.openDocuments.focusLost()
            AppPasswords.model.keepPending()
        }
    }

    /// The app ends with its last window, unless a kept entry is open and the setting keeps it running for it.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        MainActor.assumeIsolated {
            // No window is left to show a vault: every one locks, whether the app goes on running or not.
            AppVaultLocking.lockAll(.lastWindowClosed)
            return !(AppConfiguration.shared.configuration.tabs.keepRunningForFavorites && AppFavorites.hasOpenEntry)
        }
    }
}
