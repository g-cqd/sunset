import SunsetPane
import SunsetShellModel

/// What the app's App Intents (Shortcuts, Spotlight, Siri; `Sources/SunsetAppMain`) reach of the app:
/// the menus' commands by name, as the command bar runs them. Only these: reading or typing into panes is the control
/// socket's, behind its switches (ADR-0129).
public enum AppIntentBridge {
    /// A command: its name and its title.
    public struct Command: Sendable, Hashable {
        public let name: String
        public let title: String
        public let symbol: String
    }

    /// The commands of the scopes that are on, in the menus' order.
    @MainActor public static var commands: [Command] {
        let scopes = AppScopes.current
        return AppCommand.table
            .filter { $0.inBar && ($0.scope.map { scopes[$0] } ?? true) }
            .map { Command(name: $0.id.rawValue, title: $0.title, symbol: $0.symbol) }
    }

    /// Runs the command named `name` on what the window in front shows; false when there is none or it would do nothing.
    @MainActor public static func run(_ name: String) -> Bool {
        guard let id = AppCommand.ID(rawValue: name), AppCommandRunner.isEnabled(id) else { return false }
        AppCommandRunner.run(id)
        return true
    }
}
