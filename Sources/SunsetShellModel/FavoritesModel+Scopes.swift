package import SunsetPane

/// What is kept when a scope of the app is turned off: the entries of that kind are unloaded, and stay, to be shown
/// again when the scope is on.
extension FavoritesModel {
    /// How many entries that are open have a pane of the scope.
    package func openCount(of scope: Scopes.Scope) -> Int {
        favorites.entries.count { $0.isOpen && $0.has(kind: scope.kind) }
    }

    /// Unloads every open entry that has a pane of the scope.
    package func unload(_ scope: Scopes.Scope) {
        for entry in favorites.entries where entry.isOpen && entry.has(kind: scope.kind) { unload(entry.id) }
    }
}
