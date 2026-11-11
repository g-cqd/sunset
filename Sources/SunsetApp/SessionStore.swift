import AppKit
import SunsetConfig
import SunsetPane

/// The tabs that come back: the windows are written to the session file a moment after anything changes (and when the app is put away or quits) and read at
/// the next launch, where each window takes one saved window in turn. Programs cannot be saved, so a restored pane is a new shell in the directory the old one was in.
@MainActor
final class SessionStore {
    static let shared = SessionStore()

    /// Where the app keeps its own files (the saved session, the shell's start files).
    static var directory: String {
        let path = SessionLocation.path(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())
        return path.lastIndex(of: "/").map { String(path[..<$0]) } ?? "."
    }

    private let path = SessionLocation.path(environment: ProcessInfo.processInfo.environment, home: NSHomeDirectory())
    /// Saved windows no window has taken yet.
    private var pending: [SavedWindow] = []
    private var writer: Task<Void, Never>?
    /// The app is quitting: its shells are about to end and close their panes, which must not shrink the file.
    private var frozen = false
    /// This launch is for the saved tabs: false when a program was named on the command line (its window must not replace the saved session).
    private var active = true

    /// Reads the file, once, at launch. Does nothing when restoring is off, or the command line named a program to run.
    func load(enabled: Bool, namedCommand: Bool) {
        active = !namedCommand
        guard enabled, !namedCommand, let data = FileManager.default.contents(atPath: path),
            let session = SavedSession(data: data)
        else { return }
        pending = session.windows
    }

    var hasPending: Bool { !pending.isEmpty }

    /// The next saved window, if any.
    func take() -> SavedWindow? { pending.isEmpty ? nil : pending.removeFirst() }

    /// Writes the session soon: a burst of changes (a window full of tabs starting) is one write.
    func scheduleSave() {
        guard active, !frozen, AppConfiguration.shared.configuration.tabs.restore else { return }
        writer?.cancel()
        writer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    /// Writes the session now, from the windows that are open (and the saved ones not yet taken, so that a quit during launch loses nothing).
    func saveNow() {
        guard active, !frozen, AppConfiguration.shared.configuration.tabs.restore else { return }
        let open = TabRegistry.shared.allWindows().map { $0.tabs.savedWindow() }
        guard let data = try? SavedSession(windows: open + pending).encoded() else { return }
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        // Written whole beside the file and moved over it, so that a crash mid-write leaves the old session, not half of a new one.
        try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    /// The app is quitting: the last write, then no more (see `frozen`).
    func finish() {
        writer?.cancel()
        saveNow()
        frozen = true
    }
}
