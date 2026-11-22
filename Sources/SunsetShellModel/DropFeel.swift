/// What a drag feels like where it would land ("haptic feedback for good placement and snapping"): one tick each time
/// the place it would land changes to another place that takes it; none while it stays, none where nothing takes it,
/// none for leaving a place.
package struct DropFeel<Place: Equatable> {
    private var last: Place?

    package init() {}

    /// The drag is over `place` now (nil: over nothing that takes it). True when a tick is due.
    package mutating func over(_ place: Place?) -> Bool {
        defer { last = place }
        guard let place else { return false }
        return place != last
    }
}
