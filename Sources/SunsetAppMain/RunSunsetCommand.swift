import AppIntents
import SunsetApp

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
