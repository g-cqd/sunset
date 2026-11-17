extension Favorites.Entry {
    /// The same name, icon and command, and the same things to start from in the same places: what a copy shares with
    /// its original, whose ids and panes are its own.
    func looks(like other: Favorites.Entry) -> Bool {
        title == other.title && icon == other.icon && command == other.command
            && home.layout.panes.map { home.contents[$0] } == other.home.layout.panes.map { other.home.contents[$0] }
    }
}
