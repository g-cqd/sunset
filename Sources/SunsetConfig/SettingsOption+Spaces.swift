extension SettingsOption {
    /// Whose the Favorites and the Pinned grid are.
    static let spaces: [Self] =
        [
            choice(
                "spaces.favorites",
                "Favorites",
                "favorites space profile shared own list",
                \.spaces.favorites,
                [(.space, "Each Space has its own"), (.profile, "Shared by the Spaces of a profile")]
            )
            .noted("Takes effect the next time Sunset opens."),
            choice(
                "spaces.pinned",
                "Pinned tabs",
                "pinned grid profile app shared",
                \.spaces.pinned,
                [(.profile, "Each profile has its own"), (.app, "Shared by every profile")]
            )
            .noted("Takes effect the next time Sunset opens.")
        ]
}
