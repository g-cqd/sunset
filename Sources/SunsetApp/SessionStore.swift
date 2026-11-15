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

    private let storage = AppStorage.shared
    private var path: String { storage.places.session }
    /// What seals the session; nil when there is no key in this run (nothing is then written).
    private lazy var seal = storage.seal(.session)
    /// The file is sealed with a key this Mac does not have: it is never written over.
    private var locked = false
    /// The plain file of before sealing, read in this run: put away once the sealed one is written and reads back.
    private var legacy: String?
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
        guard !namedCommand, let session = read() else { return }
        AppFavorites.shared.restore(session.favorites, reopening: enabled)
        if enabled { pending = session.windows }
    }

    private static let what = "The saved session"
    private static let identity = "session"

    /// The saved session: the sealed file, or the plain one of before sealing when there is no sealed one. A file that does
    /// not read (damaged, or a later Sunset's) is moved aside and said, not dropped: the next save would write over it (R12).
    /// One sealed with another key is left as it is, and nothing is saved in this run.
    private func read() -> SavedSession? {
        if let seal {
            let read = SealedFile.read(path, as: Self.what, seal: seal, identity: Self.identity) {
                SavedSession(data: $0)
            }
            if let problem = read.problem { StorageProblems.shared.report(problem) }
            switch read {
                case .value(let session): return session
                case .locked:
                    locked = true
                    return nil
                case .damaged: return nil
                case .absent: break
            }
        } else if FileManager.default.fileExists(atPath: path) {
            // Sealed, and no key in this run: said by `AppStorage`.
            return nil
        }
        guard let old = storage.places.legacySession else { return nil }
        let read = StoredFile.read(old, as: Self.what) { SavedSession(data: $0) }
        if let problem = read.problem { StorageProblems.shared.report(problem) }
        if read.value != nil { legacy = old }
        return read.value
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
        guard let data = try? current(windows: restoresWindows).encoded() else { return }
        // Sealed, written whole beside the file, synced and moved over it: a crash mid-write leaves the old session, not half
        // of a new one.
        guard let seal, (try? SealedFile.write(data, to: path, seal: seal, identity: Self.identity)) != nil else {
            return
        }
        if let old = legacy {
            // The plain file goes once the sealed one reads back.
            let kept = SealedFile.read(path, as: Self.what, seal: seal, identity: Self.identity) {
                SavedSession(data: $0)
            }
            storage.retire(old, when: kept.value != nil)
            legacy = nil
        }
    }

    /// The session as it is now: the windows that are open (not the private ones, which keep nothing) and the saved ones not
    /// yet taken, when `windows`; and the Favorites.
    private func current(windows: Bool) -> SavedSession {
        let open =
            windows
            ? TabRegistry.shared.allWindows().filter { !$0.tabs.isPrivateWindow }.map { $0.tabs.savedWindow() }
                + pending : []
        return SavedSession(windows: open, favorites: AppFavorites.shared.saved())
    }

    /// The session as JSON a person can read, for Export All (R12 step ST-6): the open windows whatever the restoring setting.
    func readable() -> Data? { try? current(windows: true).encoded() }

    private var restoresWindows: Bool { AppConfiguration.shared.configuration.tabs.restore }

    /// There is something to write: the windows when restoring is on, and the Favorites whenever there are any.
    private var writes: Bool {
        active && !frozen && !locked && seal != nil && (restoresWindows || !AppFavorites.shared.favorites.isEmpty)
    }

    /// The app is quitting: the last write, then no more (see `frozen`).
    func finish() {
        writer?.cancel()
        saveNow()
        frozen = true
    }
}
