extension Design {
    /// The Now Playing cards at the foot of the sidebar (roadmap 0114).
    package enum NowPlaying {
        /// A card's corner: a floating surface's.
        package static let radius = 12.0
        /// From a card's edges to what it holds.
        package static let inset = Space.s
        /// The picture at a card's leading edge: the site's icon, or a symbol.
        package static let picture = 22.0
        /// The play and pause button, larger than the others around it.
        package static let mainControl = 1.3
        /// How much of each card behind the front one shows above it.
        package static let peek = 5.0
        /// How much smaller each card behind is than the one in front of it.
        package static let shrink = 0.06
        /// How dim each card behind is: it shows its surface only, never what it holds.
        package static let behind = 0.7
        /// The points a scroll travels to bring the next card to the front.
        package static let scrollStep = 24.0
    }
}
