import AppIntents
import SunsetApp

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
