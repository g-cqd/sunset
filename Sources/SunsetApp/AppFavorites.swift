import SunsetShell

/// The one Favorites of the app, shown in every window; a change is saved with the session.
@MainActor enum AppFavorites {
    static let shared: FavoritesModel = {
        let model = FavoritesModel()
        model.onChange = { SessionStore.shared.scheduleSave() }
        model.makeSealer = { CommandSealKey.load().map(AppCommandSeal.init) }
        return model
    }()
}
