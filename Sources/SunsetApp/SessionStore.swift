import AppKit
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetShell
import SunsetStorage

/// The tabs that come back: the Space and the windows that show it are written to the session file a moment after anything
/// changes (and when the app is put away or quits) and read at the next launch, where each window takes one saved view in
/// turn (`SpacesSession`, ADR-0045). Programs cannot be saved, so a restored pane is a new shell in the directory the old
/// one was in. The Favorites are in the same file. They are kept whatever the restoring setting says: with it off, the
/// tabs are not written and no entry comes back open.
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
    /// Saved views no window has taken yet; and, where a window is one tab, the saved tabs no window has taken yet.
    private var pendingViews: [SavedView] = []
    private var pending: [SavedWindow] = []
    /// What the last window of the Space showed when it closed: the next window shows it again, and so does the next launch.
    private var lastView: SavedView?
    private var writer: Task<Void, Never>?
    /// The app is quitting: its shells are about to end and close their panes, which must not shrink the file.
    private var frozen = false
    /// This launch is for the saved tabs: false when a program was named on the command line (its window must not replace the saved session).
    private var active = true

    /// Reads the file, once, at launch: the Favorites, and the windows when restoring is on. Does nothing when the command line named a program to run.
    func load(enabled: Bool, namedCommand: Bool) {
        active = !namedCommand
        guard !namedCommand, let session = read(), let first = session.spaces.first else { return }
        AppSpaces.all.profiles.restore(session.profiles, reopening: enabled)
        guard hostsTabs else {
            // A window is one tab: the first Space's saved tabs each wait for a window; the other Spaces are kept as they are.
            let named = SavedSpace(space: first.space, favorites: first.favorites)
            AppSpaces.all.restore([named] + session.spaces.dropFirst(), reopening: enabled)
            if enabled { pending = Self.windows(of: first) }
            return
        }
        AppSpaces.all.restore(session.spaces, reopening: enabled)
        // Nor does anything of a scope that is off (roadmap 0033).
        AppScopes.enforce()
        // Tabs that were left by the last window long enough ago do not come back (`tabs.closeStoppedAfter`).
        AppSpaces.cleanStopped()
        guard enabled, AppSpaces.all.spaces.contains(where: { !$0.tabs.isEmpty }) else { return }
        // Tabs with no window recorded (the last one was closed, then the app): one window, on the first tab there is.
        let shown = AppSpaces.all.spaces.first { !$0.tabs.isEmpty }
        let fallback = shown.map { [SavedView(space: $0.space.id, selected: $0.tabs.items.first?.id)] } ?? []
        pendingViews = session.views.isEmpty ? fallback : session.views
    }

    private var hostsTabs: Bool { AppConfiguration.shared.presentation.hostsTabsInWindow }

    /// Each tab of a saved Space as a window of its own.
    private static func windows(of space: SavedSpace) -> [SavedWindow] {
        space.tabs.items.map { item in
            var one = Workspace()
            one.insert(item, at: 0)
            return SavedWindow(workspace: one.selecting(item.id, entry: nil), contents: space.contents)
        }
    }

    private static let what = "The saved session"
    private static let identity = "session"

    /// The saved session: the sealed file, or the plain one of before sealing when there is no sealed one. A file that does
    /// not read (damaged, or a later Sunset's) is moved aside and said, not dropped: the next save would write over it (R12).
    /// One sealed with another key is left as it is, and nothing is saved in this run.
    private func read() -> SpacesSession? {
        if let seal {
            let read = SealedFile.read(path, as: Self.what, seal: seal, identity: Self.identity) {
                SpacesSession(data: $0, ownership: AppSpaces.ownership)
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
        let read = StoredFile.read(old, as: Self.what) { SpacesSession(data: $0, ownership: AppSpaces.ownership) }
        if let problem = read.problem { StorageProblems.shared.report(problem) }
        if read.value != nil { legacy = old }
        return read.value
    }

    var hasPending: Bool { !pending.isEmpty || !pendingViews.isEmpty }

    /// The next saved tab, for a window that is one tab.
    func take() -> SavedWindow? { pending.isEmpty ? nil : pending.removeFirst() }

    /// The next saved view of the Space; with none waiting, what its last window showed when it closed.
    func takeView() -> SavedView? {
        if !pendingViews.isEmpty { return pendingViews.removeFirst() }
        defer { lastView = nil }
        return lastView
    }

    /// `tabs`' window is closing: when it is the last window on any Space, what it showed is kept for the next.
    func closing(_ tabs: TabsModel) {
        let spaces = AppSpaces.all
        guard spaces.contains(tabs.space), spaces.spaces.reduce(0, { $0 + $1.viewerCount }) <= 1 else { return }
        lastView = tabs.savedView()
    }

    /// Writes the session soon: a burst of changes (a window full of tabs starting) is one write.
    func scheduleSave() {
        guard writes else { return }
        writer?.cancel()
        writer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.saveNow(inBackground: true)
        }
    }

    /// Where a session write is sealed and synced, one after the other, off the main thread (roadmap 0049: a write held the
    /// main thread for milliseconds each time a change settled).
    private static let disk = DispatchQueue(label: "studio.aemi.sunset.session-write", qos: .utility)

    /// Writes the session now, from the windows that are open (and the saved ones not yet taken, so that a quit during launch loses nothing).
    /// - Parameter inBackground: sealed and written off the main thread (a scheduled save); else here, waiting for any write
    ///   under way first (a quit, the app going to the background).
    func saveNow(inBackground: Bool = false) {
        guard writes else { return }
        let started = ContinuousClock.now
        defer { SaveProbe.record(ContinuousClock.now - started, inBackground: inBackground) }
        guard let data = try? current(windows: restoresWindows).encoded(), let seal else { return }
        let path = path
        // Sealed, written whole beside the file, synced and moved over it: a crash mid-write leaves the old session, not half
        // of a new one. One write at a time, in the order asked.
        if inBackground, legacy == nil, !SaveProbe.writesHere {
            Self.disk.async { _ = try? SealedFile.write(data, to: path, seal: seal, identity: Self.identity) }
            return
        }
        let written = Self.disk.sync {
            (try? SealedFile.write(data, to: path, seal: seal, identity: Self.identity)) != nil
        }
        guard written else { return }
        if let old = legacy {
            // The plain file goes once the sealed one reads back.
            let kept = SealedFile.read(path, as: Self.what, seal: seal, identity: Self.identity) {
                SpacesSession(data: $0, ownership: AppSpaces.ownership)
            }
            storage.retire(old, when: kept.value != nil)
            legacy = nil
        }
    }

    /// The session as it is now: the Spaces with their Favorites, and, when `windows`, their tabs and a view for each window
    /// that shows one (not the private ones, which keep nothing) and for each saved view not yet taken.
    private func current(windows: Bool) -> SpacesSession {
        let open = TabRegistry.shared.allWindows().map(\.tabs).filter { !$0.isPrivateWindow }
        var spaces = AppSpaces.all.saved()
        if !windows { spaces = spaces.map { SavedSpace(space: $0.space, favorites: $0.favorites) } }
        guard hostsTabs else {
            // A window is one tab: the first Space's tabs are the windows', in the windows' order.
            let old = SavedSession(
                windows: windows ? open.map { $0.savedWindow() } + pending : [],
                // The Favorites are the profiles' (below).
                favorites: SavedFavorites()
            )
            let session = SpacesSession(old, space: AppSpaces.shared.space, ownership: AppSpaces.ownership)
            var first = session.spaces
            if let own = spaces.first?.favorites, !first.isEmpty { first[0].favorites = own }
            return SpacesSession(
                spaces: first + spaces.dropFirst(),
                views: session.views,
                profiles: AppSpaces.all.profiles.saved(favorites: !AppSpaces.ownership.favoritesBySpace),
                ownership: AppSpaces.ownership
            )
        }
        var views: [SavedView] = []
        if windows {
            views = open.filter { AppSpaces.all.contains($0.space) }.map { $0.savedView() } + pendingViews
            if views.isEmpty, let lastView { views = [lastView] }
        }
        return SpacesSession(
            spaces: spaces,
            views: views,
            profiles: AppSpaces.all.profiles.saved(favorites: !AppSpaces.ownership.favoritesBySpace),
            ownership: AppSpaces.ownership
        )
    }

    /// The session as JSON a person can read, for Export All (R12 step ST-6): the open windows whatever the restoring setting.
    func readable() -> Data? { try? current(windows: true).encoded() }

    private var restoresWindows: Bool { AppConfiguration.shared.configuration.tabs.restore }

    /// There is something to write: the windows when restoring is on, and the Favorites whenever there are any.
    private var writes: Bool {
        active && !frozen && !locked && seal != nil
            && (restoresWindows || AppSpaces.all.spaces.count > 1 || !AppFavorites.shared.favorites.isEmpty
                || AppSpaces.all.profiles.profiles.count > 1 || !AppFavorites.pinned.favorites.isEmpty)
    }

    /// The app is quitting: the last write, then no more (see `frozen`).
    func finish() {
        writer?.cancel()
        saveNow()
        frozen = true
    }
}
