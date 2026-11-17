import SunsetShell

/// The Favorites of the Spaces: a change is saved with the session, and a kept terminal's command is sealed with the app's
/// key. `shared` is the first Space's, which is also what a window that is one tab shows.
@MainActor enum AppFavorites {
    static let shared = make()

    /// The Favorites of a new Space.
    static func make() -> FavoritesModel {
        let model = FavoritesModel()
        model.onChange = { SessionStore.shared.scheduleSave() }
        model.makeSealer = { CommandSealKey.load().map(AppCommandSeal.init) }
        return model
    }

    /// The Pinned grid: the app's, the same in every Space, until there are profiles (roadmap 0021, P-b; ADR-0050).
    static let pinned = make()

    /// Whether an entry is open in any Space or in the grid: something of the user's would run with no window if the
    /// app stayed.
    static var hasOpenEntry: Bool { pinned.hasOpenEntry || AppSpaces.all.spaces.contains { $0.favorites.hasOpenEntry } }
}
