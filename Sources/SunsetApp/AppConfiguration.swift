import Foundation
import Observation
import SunsetConfig
import SunsetHost

/// The configuration file as the app sees it: read at launch, watched, and re-read whenever it settles after a change. Views read `configuration` and update
/// themselves; a file that cannot be read leaves the last good configuration in force and says why.
@MainActor @Observable
final class AppConfiguration {
    static let shared = AppConfiguration()

    private(set) var configuration = Configuration()
    /// Whether a file was found (the settings of the app's own Settings window apply when there is none).
    private(set) var hasFile = false
    private(set) var issues: [ConfigurationIssue] = []
    /// Why the file could not be read at all, if it could not.
    private(set) var lastError: String?
    let path: String

    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var watching: Task<Void, Never>?

    private init() {
        path = ConfigurationLocation.path(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())
        reload()
        let watcher = FileWatcher(path: path)
        self.watcher = watcher
        watcher.start()
        watching = Task { [weak self] in
            for await _ in watcher.changes { self?.reload() }
        }
    }

    func reload() {
        guard let data = FileManager.default.contents(atPath: path) else {
            // No file: the defaults, and the app's own settings. (A file that was deleted goes back to that too.)
            if hasFile { Self.say("\(path) is gone: back to the defaults") }
            hasFile = false
            configuration = Configuration()
            issues = []
            lastError = nil
            return
        }
        hasFile = true
        do {
            let result = try ConfigurationParser.parse(String(decoding: data, as: UTF8.self))
            configuration = result.configuration
            issues = result.issues
            lastError = nil
            for issue in result.issues { Self.say("\(path): \(issue.path): \(issue.message)") }
        } catch {
            lastError = Self.describe(error)
            Self.say("\(path): \(lastError ?? "unreadable"); the previous configuration stays in force")
        }
    }

    private static func describe(_ error: ConfigurationError) -> String {
        switch error {
            case .syntax(let message, let offset): offset.map { "\(message) (byte \($0))" } ?? message
            case .notAnObject: "the file must contain an object ({ ... })"
        }
    }

    private static func say(_ message: String) {
        FileHandle.standardError.write(Data("sunset: \(message)\n".utf8))
    }
}
