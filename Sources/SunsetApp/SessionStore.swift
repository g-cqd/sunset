import AppKit
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetStorage

/// The tabs that come back: the windows are written to the session file a moment after anything changes (and when the app is put away or quits) and read at
/// the next launch, where each window takes one saved window in turn. Programs cannot be saved, so a restored pane is a new shell in the directory the old one was in.
/// The Favorites (`FavoritesStore`) are in the same file. They are kept whatever the restoring setting says: with it off, the windows are not written
/// and no entry comes back open.
@MainActor
final class SessionStore {
    static let shared = SessionStore()

    /// Where the app keeps its own files (the saved session, the shell's start files).
    static var directory: String { StoragePlaces.current.directory }

    private let path = StoragePlaces.current.session
    /// Saved windows no window has taken yet.
    private var pending: [SavedWindow] = []
    private var writer: Task<Void, Never>?
    /// The app is quitting: its shells are about to end and close their panes, which must not shrink the file.
    private var frozen = false
    /// This launch is for the saved tabs: false when a program was named on the command line (its window must not replace the saved session).
    private var active = true

    /// Reads the file, once, at launch: the Favorites, and the windows when restoring is on. Does nothing when the command line named a program to run.
    func load(enabled: Bool, namedCommand: Bool) {
        active = !namedCommand
        guard !namedCommand else { return }
        // A session that does not read (damaged, or written by a later Sunset) is moved aside and said, not dropped (R12): the
        // next save would otherwise write over it.
        let read = StoredFile.read(path, as: "The saved session") { SavedSession(data: $0) }
        if case .damaged(let problem) = read { StorageProblems.shared.report(problem) }
        guard let session = read.value else { return }
        AppFavorites.shared.restore(session.favorites, reopening: enabled)
        if enabled { pending = session.windows }
    }

    var hasPending: Bool { !pending.isEmpty }

    /// The next saved window, if any.
    func take() -> SavedWindow? { pending.isEmpty ? nil : pending.removeFirst() }

    /// Writes the session soon: a burst of changes (a window full of tabs starting) is one write.
    func scheduleSave() {
        guard writes else { return }
        writer?.cancel()
        writer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    /// Writes the session now, from the windows that are open (and the saved ones not yet taken, so that a quit during launch loses nothing).
    func saveNow() {
        guard writes else { return }
        let open =
            restoresWindows
            ? TabRegistry.shared.allWindows().filter { !$0.tabs.isPrivateWindow }.map { $0.tabs.savedWindow() }
                + pending : []
        let session = SavedSession(windows: open, favorites: AppFavorites.shared.saved())
        guard let data = try? session.encoded() else { return }
        // Written whole beside the file, synced and moved over it: a crash mid-write leaves the old session, not half of a new one.
        try? StoredFile.write(data, to: path)
    }

    private var restoresWindows: Bool { AppConfiguration.shared.configuration.tabs.restore }

    /// There is something to write: the windows when restoring is on, and the Favorites whenever there are any.
    private var writes: Bool {
        active && !frozen && (restoresWindows || !AppFavorites.shared.favorites.isEmpty)
    }

    /// The app is quitting: the last write, then no more (see `frozen`).
    func finish() {
        writer?.cancel()
        saveNow()
        frozen = true
    }
}
