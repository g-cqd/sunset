import AppIntents
import SunsetApp

/// A command of Sunset's menus, as Shortcuts and Spotlight offer it.
struct SunsetCommand: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Sunset Command")
    static let defaultQuery = SunsetCommandQuery()

    let id: String
    let title: String
    let symbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: symbol))
    }
}

/// The commands, found by name or by words of their title.
struct SunsetCommandQuery: EntityStringQuery {
    @MainActor func entities(for identifiers: [String]) async throws -> [SunsetCommand] {
        Self.all().filter { identifiers.contains($0.id) }
    }

    @MainActor func entities(matching string: String) async throws -> [SunsetCommand] {
        let words = string.lowercased().split(separator: " ")
        return Self.all().filter { command in words.allSatisfy { command.title.lowercased().contains($0) } }
    }

    @MainActor func suggestedEntities() async throws -> [SunsetCommand] {
        Self.all()
    }

    @MainActor private static func all() -> [SunsetCommand] {
        AppIntentBridge.commands.map { SunsetCommand(id: $0.name, title: $0.title, symbol: $0.symbol) }
    }
}

/// Runs a command of the menus in the window in front, as the command bar does.
struct RunSunsetCommand: AppIntent {
    static let title: LocalizedStringResource = "Run Sunset Command"
    static let description = IntentDescription("Runs a command of Sunset's menus in the window in front.")
    static let openAppWhenRun = true

    @Parameter(title: "Command") var command: SunsetCommand

    @MainActor func perform() async throws -> some IntentResult {
        guard AppIntentBridge.run(command.id) else {
            throw $command.needsValueError("\(command.title) would do nothing now. Which command?")
        }
        return .result()
    }
}

/// What Spotlight and Siri offer without a shortcut made.
struct SunsetShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RunSunsetCommand(),
            phrases: ["Run \(\.$command) in \(.applicationName)", "\(.applicationName) \(\.$command)"],
            shortTitle: "Run Command",
            systemImageName: "command"
        )
    }
}
