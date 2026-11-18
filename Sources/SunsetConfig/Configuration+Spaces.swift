extension Configuration {
    /// Whose the Favorites and the Pinned grid are (roadmap 0044; the owner, 2026-11-17): by default the Favorites are each
    /// Space's and the grid each profile's. Read when Sunset opens.
    public struct Spaces: Sendable, Equatable {
        public var favorites = FavoritesScope.space
        public var pinned = PinnedScope.profile

        public enum FavoritesScope: String, Sendable, Equatable, CaseIterable {
            /// Each Space has its own.
            case space
            /// One list for the Spaces of a profile (ADR-0055).
            case profile
        }

        public enum PinnedScope: String, Sendable, Equatable, CaseIterable {
            /// Each profile has its own grid (ADR-0053).
            case profile
            /// One grid for the whole app.
            case app
        }

        public init() {}
    }
}
