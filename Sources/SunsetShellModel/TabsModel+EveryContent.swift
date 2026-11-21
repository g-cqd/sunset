extension TabsModel {
    /// Every content this window can show: its Space's tabs, its open favorites, and its profile's open pinned tabs (what
    /// extensions see as the window's tabs).
    package var everyContent: [any PaneContent] {
        var seen = Set<ObjectIdentifier>()
        let all =
            Array(contents.values) + Array(favorites.contents.values) + Array(pinned?.contents.values ?? [:].values)
        return all.filter { seen.insert(ObjectIdentifier($0)).inserted }
    }
}
