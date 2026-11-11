import Observation
import SunsetPane

/// The Favorites of the app (`Favorites`): one tree of folders and kept entries, shown in every window. For now it is only read from the session file at
/// launch and written back with it: nothing in a window shows or edits it yet (folders step a2).
@MainActor @Observable
final class FavoritesStore {
    static let shared = FavoritesStore()

    private(set) var favorites = Favorites()
    /// What brings back the content of the panes that were live when the session was written, until something shows them.
    @ObservationIgnored private var pending: [PaneID: PaneDescriptor] = [:]

    private init() {}

    /// Takes the Favorites of the session file. The entries that were open stay open when `reopening` (the tabs of the last run come back); otherwise
    /// every entry is kept and none is open.
    func restore(_ saved: SavedFavorites, reopening: Bool) {
        favorites = saved.favorites
        pending = saved.contents
        guard !reopening else { return }
        favorites.unloadAll()
        pending = [:]
    }

    /// The Favorites as they are, for the session file.
    func saved() -> SavedFavorites { SavedFavorites(favorites: favorites, contents: pending) }
}
