extension Design {
    /// The Now Playing cards at the foot of the sidebar (roadmap 0114).
    package enum NowPlaying {
        /// A card's corner: a floating surface's.
        package static let radius = 12.0
        /// From a card's edges to what it holds.
        package static let inset = Space.m
        /// The picture at a card's leading edge: the site's icon, or a symbol.
        package static let picture = 28.0
        /// How much of each card behind the front one shows above it.
        package static let peek = 5.0
        /// How much smaller each card behind is than the one in front of it.
        package static let shrink = 0.05
        /// How faint each card behind is.
        package static let behind = 0.55
        /// The points a scroll travels to bring the next card to the front.
        package static let scrollStep = 24.0
    }
}
