/// A profile as the session keeps it: what names it, and its Pinned grid.
public struct SavedProfile: Sendable, Equatable, Codable {
    public var profile: Profile
    public var pinned: SavedFavorites

    public init(profile: Profile, pinned: SavedFavorites = SavedFavorites()) {
        self.profile = profile
        self.pinned = pinned
    }
}
