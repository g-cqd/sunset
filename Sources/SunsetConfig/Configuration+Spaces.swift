extension Configuration {
    /// Whose the Favorites and the Pinned grid are: by default the Favorites are each Space's and the grid each
    /// profile's. Read when Sunset opens.
    public struct Spaces: Sendable, Equatable {
        public var favorites = FavoritesScope.space
        public var pinned = PinnedScope.profile

        public enum FavoritesScope: String, Sendable, Equatable, CaseIterable {
            /// Each Space has its own.
            case space
            /// One list for the Spaces of a profile.
            case profile
        }

        public enum PinnedScope: String, Sendable, Equatable, CaseIterable {
            /// Each profile has its own grid.
            case profile
            /// One grid for the whole app.
            case app
        }

        public init() {}
    }
}
