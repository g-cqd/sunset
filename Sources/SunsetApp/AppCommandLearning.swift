import Foundation
import SunsetShellModel

/// What the command bar learnt of the commands run from it (`CommandLearning`), kept between launches in the app's
/// defaults: only the words typed to find a command, and how often each was run.
@MainActor enum AppCommandLearning {
    private static let key = "commandBar.learnt"

    private(set) static var current = CommandLearning(saved: UserDefaults.standard.stringArray(forKey: key) ?? [])

    /// `command` was run from the bar with `typed` in its field.
    static func ran(_ command: AppCommand.ID, typed: String) {
        current.ran(command, typed: typed)
        UserDefaults.standard.set(current.saved, forKey: key)
    }
}
