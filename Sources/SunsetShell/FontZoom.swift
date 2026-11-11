/// A window's temporary change of the font size (⌘+, ⌘−, ⌘0): points added to the configured size, never written to the file, kept in the range the
/// configuration accepts for `font.size`.
package struct FontZoom: Sendable, Equatable {
    package static let range = 4.0 ... 200.0

    package private(set) var offset: Double

    package init(offset: Double = 0) { self.offset = offset }

    package var isReset: Bool { offset == 0 }

    /// The size to draw with for a configured `base`.
    package func size(base: Double) -> Double { min(max(base + offset, Self.range.lowerBound), Self.range.upperBound) }

    /// Changes the size by `points`; the offset stops where the size stops (zooming in again at once changes the size, with no hidden distance to cover first).
    package mutating func step(by points: Double, base: Double) {
        offset = min(max(base + offset + points, Self.range.lowerBound), Self.range.upperBound) - base
    }

    package mutating func reset() { offset = 0 }
}
