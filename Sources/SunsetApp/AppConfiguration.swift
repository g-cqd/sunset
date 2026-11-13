import AppKit
import Foundation
import Observation
import SunsetConfig
import SunsetHost

/// The configuration file as the app sees it: read at launch, watched, and re-read whenever it settles after a change. Views read `configuration` and update
/// themselves; a file that cannot be read leaves the last good configuration in force and says why.
@MainActor @Observable
final class AppConfiguration {
    /// The sidebar's pin button: it stays beside the content, or hides and floats (`sidebar.autoHide`).
    static func togglePin() { shared.update { $0.sidebar.autoHide.toggle() } }

    static let shared = AppConfiguration()

    private(set) var configuration = Configuration() {
        didSet {
            if configuration.appearance.scheme != oldValue.appearance.scheme { applyScheme() }
        }
    }

    /// `appearance.scheme` for the whole app (Settings, panels, menus), not only the terminal windows: dark or light locks it,
    /// system follows the Mac (owner, 2026-11-13).
    func applyScheme() {
        NSApp?.appearance = configuration.appearance.scheme.nsAppearance
    }
    /// How the tabs are shown now.
    var presentation: TabPresentation { configuration.presentation }
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
    /// What was in force at the last load or save: an edit is written relative to it (so what a theme brought is not copied into the file).
    @ObservationIgnored private var baseline = Configuration()
    @ObservationIgnored private var themeWatcher: FileWatcher?
    @ObservationIgnored private var themeWatching: Task<Void, Never>?
    @ObservationIgnored private var watchedTheme: String?

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
    /// later, by editing it in place (comments and order stay), or whole when there is no readable file; the first save of a session keeps the old file as `config.json.bak`.
    func update(_ edit: (inout Configuration) -> Void) {
        var changed = configuration
        edit(&changed)
        guard changed != configuration else { return }
        apply(changed)
        hasFile = true
        scheduleSave()
    }

    /// Writes a change still waiting (the app is quitting: "Don't ask again" must not be lost).
    func saveNow() {
        guard saving != nil else { return }
        saving?.cancel()
        saving = nil
        save()
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
        let manager = FileManager.default
        // An existing file is edited in place (its comments and order stay); a new or unreadable one is written whole.
        let existing = manager.contents(atPath: path).map { String(decoding: $0, as: UTF8.self) }
        let text =
            existing.flatMap { ConfigurationPatcher.saved(configuration, replacing: baseline, over: $0) }
            ?? ConfigurationWriter.text(for: configuration)
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
            baseline = configuration
            try text.write(toFile: path, atomically: true, encoding: .utf8)
            lastError = nil
        } catch {
            lastError = "could not save \(path): \(error.localizedDescription)"
            Self.say(lastError ?? "")
        }
    }

    /// Sets the configuration; when the way tabs are shown changed, the open terminals move to where the new presentation keeps them.
    private func apply(_ new: Configuration) {
        let before = configuration.presentation
        configuration = new
        let after = new.presentation
        // At launch the file is read before the application exists (`NSApp` is nil then, and there is no window to move): nothing to reshape.
        if before != after, (NSApp as NSApplication?) != nil { AppActions.shared.reshape(from: before, to: after) }
    }

    func reload() {
        guard let data = FileManager.default.contents(atPath: path) else {
            // No file: the defaults, and the app's own settings. (A file that was deleted goes back to that too.)
            if hasFile { Self.say("\(path) is gone: back to the defaults") }
            hasFile = false
            apply(Configuration())
            baseline = configuration
            issues = []
            lastError = nil
            watchTheme(nil)
            return
        }
        hasFile = true
        let text = String(decoding: data, as: UTF8.self)
        if text == lastWritten { return }
        do {
            let result = try ConfigurationLoader.load(text) { [path] name in
                FileManager.default.contents(atPath: ConfigurationLocation.themePath(named: name, besideConfig: path))
                    .map { String(decoding: $0, as: UTF8.self) }
            }
            apply(result.configuration)
            baseline = result.configuration
            watchTheme(result.configuration.theme)
            issues = result.issues
            lastError = nil
            for issue in result.issues { Self.say("\(path): \(issue.path): \(issue.message)") }
        } catch {
            lastError = Self.describe(error)
            Self.say("\(path): \(lastError ?? "unreadable"); the previous configuration stays in force")
        }
    }

    /// Watches the file of the theme in force too: editing a theme changes the windows as editing the configuration does.
    private func watchTheme(_ name: String?) {
        guard name != watchedTheme else { return }
        watchedTheme = name
        themeWatcher?.stop()
        themeWatching?.cancel()
        themeWatcher = nil
        guard let name, ConfigurationLoader.isSafeThemeName(name) else { return }
        let watcher = FileWatcher(path: ConfigurationLocation.themePath(named: name, besideConfig: path))
        themeWatcher = watcher
        watcher.start()
        themeWatching = Task { [weak self] in
            for await _ in watcher.changes { self?.reloadForTheme() }
        }
    }

    /// The theme's file changed: read the configuration again (it is the same text, so the guard against our own writes is bypassed).
    private func reloadForTheme() {
        lastWritten = nil
        reload()
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
