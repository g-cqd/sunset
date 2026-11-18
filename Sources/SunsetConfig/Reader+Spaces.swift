internal import OrderedCollections

extension Reader {
    /// `spaces` (roadmap 0044): `favorites` (`space`, `profile`) and `pinned` (`profile`, `app`).
    mutating func readSpaces(_ object: Object) {
        for (key, value) in object {
            switch key {
                case "favorites":
                    if let scope = choice("spaces.favorites", value, as: Configuration.Spaces.FavoritesScope.self) {
                        configuration.spaces.favorites = scope
                    }
                case "pinned":
                    if let scope = choice("spaces.pinned", value, as: Configuration.Spaces.PinnedScope.self) {
                        configuration.spaces.pinned = scope
                    }
                default: unknown("spaces.\(key)")
            }
        }
    }
}
