extension Design {
    /// A tab's loading ring around its icon (owner note n61): it fills with the page's progress, its end rounded, and the icon,
    /// smaller and clipped to a circle inside it, grows back to its square when the page has loaded.
    package enum Ring {
        package static let lineWidth = 2.0
        /// The icon while loading, against its size at rest.
        package static let iconScale = 0.75
        /// The circle the icon is clipped to while loading, against the glyph's frame; at rest a circle this large clips nothing.
        package static let clipLoading = 0.62
        package static let clipAtRest = 1.5
        /// How long the ring takes to follow the progress, and the icon to grow back.
        package static let follow = 0.2
        package static let settle = 0.3
    }
}
