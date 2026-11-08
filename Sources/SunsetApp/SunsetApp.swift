import SunsetConfig
import SwiftUI

/// Sunset, the app: one window per terminal, a Settings window, a Paste command. SwiftUI owns the scenes, the settings and the menus; the terminal view
/// itself is AppKit (`TerminalNSView`).
@main struct SunsetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    private let launch = LaunchOptions.parse(CommandLine.arguments, environment: ProcessInfo.processInfo.environment)

    init() {
        // The saved tabs of the last run are read once, before the first window asks for them.
        SessionStore.shared.load(
            enabled: AppConfiguration.shared.configuration.tabs.restore,
            namedCommand: launch.namedCommand
        )
    }

    var body: some Scene {
        WindowGroup(id: "terminal") {
            TerminalScene(launch: launch)
        }
        .defaultSize(width: 820, height: 520)
        .commands { TerminalCommands() }

        Settings {
            SettingsView()
        }
    }
}
