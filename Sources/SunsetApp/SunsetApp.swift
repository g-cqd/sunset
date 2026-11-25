import Foundation
import SunsetAppCore
import SunsetConfig
import SunsetShell
import SunsetStorage
public import SwiftUI

/// Sunset, the app: one window per terminal, a Settings window, a Paste command. SwiftUI owns the scenes, the settings and the menus; the terminal view
/// itself is AppKit (`TerminalNSView`).
/// A library type: `Sources/SunsetAppMain` starts it.
public struct SunsetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    private let launch = LaunchOptions.parse(CommandLine.arguments, environment: ProcessInfo.processInfo.environment)

    public init() {
        // Positional command-line arguments are the command to run in the terminal, not document files for AppKit to open (without this, AppKit suppresses
        // the initial WindowGroup window whenever an argument matches an existing file path).
        UserDefaults.standard.register(defaults: ["NSTreatUnknownArgumentsAsOpen": false])
        SystemRestoration.ignoreSavedState()
        // The other build that keeps this store, open: one at a time, before anything of the store is read.
        MainActor.assumeIsolated { OtherBuildAtLaunch.settle() }
        // The cookie jars sealed at the last quit, put back before any page's store opens.
        MainActor.assumeIsolated { AppSealedData.openAtLaunch() }
        // The saved tabs of the last run are read once, before the first window asks for them.
        // Crash detection + launch restore policy (roadmap 0024 S-3 / t214): always asks after a crash.
        let shouldRestore = MainActor.assumeIsolated {
            let places = SunsetStore.shared.places
            let hasSaved =
                FileManager.default.fileExists(atPath: places.session)
                || places.legacySession.map { FileManager.default.fileExists(atPath: $0) } == true
            return TerminalHistoryRestore.decideAtLaunch(
                places: places,
                configuration: AppConfiguration.shared.configuration,
                hasSavedSession: hasSaved
            )
        }
        SessionStore.shared.load(
            enabled: shouldRestore,
            namedCommand: launch.namedCommand
        )
    }

    public var body: some Scene {
        WindowGroup(id: "terminal") {
            TerminalScene(launch: launch)
        }
        .defaultSize(width: 820, height: 520)
        // On the first launch the welcome comes first; the window opens when it closes (`WelcomeWindow`).
        .defaultLaunchBehavior(MainActor.assumeIsolated { WelcomeWindow.atLaunch } ? .suppressed : .automatic)
        // A file opened with Sunset opens in a tab (AppDelegate), not in a window SwiftUI makes for it.
        .handlesExternalEvents(matching: [])
        .commands {
            TerminalCommands()
            SpaceCommands()
        }
        // A page's pop-up: a window of its own, not kept by the session.
        WindowGroup(id: "popup", for: UUID.self) { $id in
            if let id { PopupScene(id: id) }
        }
        .defaultSize(width: 520, height: 640)
        .restorationBehavior(.disabled)
        .handlesExternalEvents(matching: [])
        // Without this, a second window group puts the system's File ▸ Close (the window's) back in place of Sunset's
        // Close (the focused tab's): ⌘W closed the whole window (seen 2026-11-22; the menus are the terminal group's).
        .commandsRemoved()
    }
}
