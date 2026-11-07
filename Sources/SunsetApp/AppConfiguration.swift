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
    @ObservationIgnored private var saving: Task<Void, Never>?
    /// The text this process last wrote: a change of the file that is just that is not a change.
    @ObservationIgnored private var lastWritten: String?
    @ObservationIgnored private var madeBackup = false

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

    /// Changes the configuration the way the Settings window does: at once in memory (so the windows follow while a slider moves), and in the file a moment
    /// later, as the whole configuration (the comments of a hand-written file are lost; the first save of a session keeps the old file as `config.json.bak`).
    func update(_ edit: (inout Configuration) -> Void) {
        var changed = configuration
        edit(&changed)
        guard changed != configuration else { return }
        configuration = changed
        hasFile = true
        scheduleSave()
    }

    private func scheduleSave() {
        saving?.cancel()
        saving = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            self?.save()
        }
    }

    private func save() {
        let text = ConfigurationWriter.text(for: configuration)
        let manager = FileManager.default
        do {
            try manager.createDirectory(
                atPath: (path as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true
            )
            if !madeBackup, manager.fileExists(atPath: path) {
                madeBackup = true
                let backup = path + ".bak"
                try? manager.removeItem(atPath: backup)
                try manager.copyItem(atPath: path, toPath: backup)
            }
            lastWritten = text
            try text.write(toFile: path, atomically: true, encoding: .utf8)
            lastError = nil
        } catch {
            lastError = "could not save \(path): \(error.localizedDescription)"
            Self.say(lastError ?? "")
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
        let text = String(decoding: data, as: UTF8.self)
        if text == lastWritten { return }
        do {
            let result = try ConfigurationParser.parse(text)
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
