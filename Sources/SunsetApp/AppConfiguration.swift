import AppKit
import Foundation
import Observation
import SunsetAppCore
import SunsetConfig
import SunsetHost
import SunsetRuntime
import SunsetShell
import SunsetStorage
import SunsetWeb

/// The configuration file as the app sees it: read at launch, watched, and re-read whenever it settles after a change. Views read `configuration` and update
/// themselves; a file that cannot be read leaves the last good configuration in force and says why.
@MainActor @Observable
final class AppConfiguration {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    @ObservationIgnored var runtime = Runtime.live

    /// The sidebar's pin button: it stays beside the content, or hides and floats (`sidebar.autoHide`).
    static func togglePin() {
        shared.update { $0.sidebar.autoHide.toggle() }
    }

    static let shared = AppConfiguration()

    private(set) var configuration = Configuration() {
        didSet {
            if configuration.appearance.scheme != oldValue.appearance.scheme { applyScheme() }
            if configuration.appearance.icon != oldValue.appearance.icon { applyIcon() }
            Feedback.taps = configuration.appearance.haptics
            WebShare.otherProfiles = configuration.web.shareOtherProfiles
            if configuration.passwords != AppPasswords.settings { AppPasswords.settings = configuration.passwords }
            refreshShown()
        }
    }

    /// What the windows draw from: the configuration, its tint the light scheme's while the app is light (`appearance.tint.light`,
    /// `lightAlpha`), a dark terminal theme opaque then.
    /// Settings edits `configuration`; a window never writes this back.
    private(set) var shown = Configuration()
    /// The app is drawn light now: the scheme locked to light, or the system's while it follows it.
    private(set) var isLight = false
    @ObservationIgnored private var appearanceWatch: NSKeyValueObservation?

    /// `appearance.scheme` for the whole app (Settings, panels, menus), not only the terminal windows: dark or light locks it,
    /// system follows the Mac.
    func applyScheme() {
        NSApp?.appearance = configuration.appearance.scheme.nsAppearance
        if appearanceWatch == nil, let app = NSApp {
            appearanceWatch = app.observe(\.effectiveAppearance) { [runtime] _, _ in
                runtime.task { @MainActor in
                    AppConfiguration.shared.refreshShown()
                }
            }
        }
        refreshShown()
    }

    private func refreshShown() {
        let light: Bool =
            switch configuration.appearance.scheme {
                case .light: true
                case .dark: false
                case .system: NSApp?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
            }
        let next = ShownConfiguration.make(configuration, light: light)
        if light != isLight { isLight = light }
        if next != shown { shown = next }
    }
    /// How the tabs are shown now.
    var presentation: TabPresentation {
        configuration.presentation
    }
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
    @ObservationIgnored var lastWritten: String?
    @ObservationIgnored private var madeBackup = false
    /// What was in force at the last load or save: an edit is written relative to it (so what a theme brought is not copied into the file).
    @ObservationIgnored private var baseline = Configuration()
    @ObservationIgnored var themeWatcher: FileWatcher?
    @ObservationIgnored var themeWatching: Task<Void, Never>?
    @ObservationIgnored var iconSchedule: Task<Void, Never>?
    @ObservationIgnored var iconObservers: [any NSObjectProtocol] = []
    @ObservationIgnored var watchedTheme: String?

    private init() {
        path = ConfigurationLocation.path(
            environment: ProcessInfo.processInfo.environment,
            home: NSHomeDirectory(),
            variant: StoragePlaces.current.variant
        )
        reload()
        let watcher = FileWatcher(path: path)
        self.watcher = watcher
        watcher.start()
        watching = runtime.task(role: .observation) { [weak self] in
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
        saving = runtime.task { [weak self, runtime] in
            await runtime.sleep(for: .milliseconds(250))
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
        // After SwiftUI has applied the change that set it (a Settings toggle): closing windows inside that update trips SwiftUI's bar
        // appearance bridge (crash report 2026-11-13).
        if before != after, (NSApp as NSApplication?) != nil {
            runtime.task { @MainActor in AppActions.shared.reshape(from: before, to: after) }
        }
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
            lastError = error.description
            Self.say("\(path): \(lastError ?? "unreadable"); the previous configuration stays in force")
        }
    }

    private static func say(_ message: String) {
        FileHandle.standardError.write(Data("sunset: \(message)\n".utf8))
    }
}

extension AppConfiguration {
    /// `web.showOpenedPages`: a page a page opens is shown.
    var showsOpenedPages: Bool {
        configuration.web.showOpenedPages
    }
}
