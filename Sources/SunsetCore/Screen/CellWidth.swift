public enum CellWidth: UInt8, Sendable {
    case narrow = 0
    /// The left half of a double-width character; the next cell is its `spacerTail`.
    case wide = 1
    case spacerTail = 2
    /// The blank at the end of a row where a double-width character did not fit and went to the next row; a reflow drops it.
    case spacerHead = 3
}
