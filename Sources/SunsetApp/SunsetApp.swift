import Foundation
import SunsetConfig
import SunsetShell
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
        // The saved tabs of the last run are read once, before the first window asks for them.
        SessionStore.shared.load(
            enabled: AppConfiguration.shared.configuration.tabs.restore,
            namedCommand: launch.namedCommand
        )
    }

    public var body: some Scene {
        WindowGroup(id: "terminal") {
            TerminalScene(launch: launch)
        }
        .defaultSize(width: 820, height: 520)
        .commands { TerminalCommands() }
    }
}
