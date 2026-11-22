/// A profile as the session keeps it: what names it, its Pinned grid and its Favorites.
public struct SavedProfile: Sendable, Equatable, Codable {
    public var profile: Profile
    public var pinned: SavedFavorites
    /// The profile's Favorites: the same in each of its Spaces.
    public var favorites: SavedFavorites

    public init(
        profile: Profile,
        pinned: SavedFavorites = SavedFavorites(),
        favorites: SavedFavorites = SavedFavorites()
    ) {
        self.profile = profile
        self.pinned = pinned
        self.favorites = favorites
    }

    private enum Key: String, CodingKey { case profile, pinned, favorites }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        profile = try container.decode(Profile.self, forKey: .profile)
        pinned = (try? container.decodeIfPresent(SavedFavorites.self, forKey: .pinned)) ?? SavedFavorites()
        favorites = (try? container.decodeIfPresent(SavedFavorites.self, forKey: .favorites)) ?? SavedFavorites()
    }
}
