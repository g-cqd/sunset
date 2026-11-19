/// How a sidebar row is set apart (R3 step d; the owner, 2026-11-17: "the focused tab should still show that it is
/// selected"): among several rows selected, the shown one is drawn in the selection's accent too, stronger than the others,
/// with its hairline; alone, the shown row has the plain highlight.
package enum RowEmphasis: Equatable, Sendable {
    case none, shown, marked, markedShown

    /// The emphasis of a row that is `shown` (its tab is the one on screen) and `marked` (among several selected).
    /// - Parameters:
    ///   - shown: Its tab is the one shown.
    ///   - marked: It is among the rows selected together.
    /// - Returns: The emphasis.
    package static func of(shown: Bool, marked: Bool) -> Self {
        switch (shown, marked) {
            case (true, true): .markedShown
            case (true, false): .shown
            case (false, true): .marked
            case (false, false): .none
        }
    }

    /// Drawn in the selection's accent.
    package var isAccent: Bool {
        self == .marked || self == .markedShown
    }
}
