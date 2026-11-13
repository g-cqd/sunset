extension Design {
    /// The built-in tab bar while it holds the address (t223): one row of capsules as tall as a bar group's.
    package enum TabCapsules {
        /// Smaller than a bar group (owner, 2026-11-13): the row's buttons are whole circles of this size, its tabs one line.
        package static let height = 34.0
        /// A capsule's corner: half its height.
        package static let radius = height / 2
        /// Between two tabs: a point less than between the row's other items (owner, 2026-11-13).
        package static let tabGap = Space.m - 1
        /// From the bar's edges to its capsules, above and below.
        package static let inset = Space.s
        /// The row's height.
        package static let bar = height + 2 * inset
        /// The window's buttons centred on the row, as far from the window's leading edge as from its top: the middle of the row.
        package static let lightsCenter = bar / 2
        /// The system's window button (13.5 pt drawn in a 14 pt frame).
        package static let lightWidth = 14.0
        /// The first light's leading edge: as far from the window's edge as its top is from the window's top.
        package static let lightsX = lightsCenter - lightWidth / 2
        /// From the window's leading edge to the first capsule: the lights and the gap between capsules after them.
        package static let lightsClearance = lightsX + 2 * System.lightsPitch + lightWidth + Space.m
    }
}
