/// Blocks that were changed here and on disk, differently (roadmap 0023 step M-e). The text keeps what was written here; what
/// the disk says is kept beside it until the person answers. The file is not written while one waits.
public struct DocumentConflict: Identifiable, Equatable, Sendable {
    public enum Answer: Sendable {
        /// What is here stays.
        case mine
        /// What the disk says replaces what is here.
        case theirs
        /// What is here, then what the disk says.
        case both
    }

    public let id: Int
    /// Where the blocks written here are in the text now, in UTF-16 units; empty when they were removed here. It follows the
    /// text as it is edited.
    public internal(set) var range: Range<Int>
    /// What the disk says there; empty when it removed them.
    public let theirs: String
    /// What they were before either side changed them.
    public let base: String

    public init(id: Int, range: Range<Int>, theirs: String, base: String) {
        self.id = id
        self.range = range
        self.theirs = theirs
        self.base = base
    }

    /// An edit replaced `removed` units at `location` with `inserted`: the range moves with what is before it, and grows
    /// or shrinks with what is typed in it. Typed exactly at its start, or at its end, is outside.
    mutating func follow(location: Int, removed: Int, inserted: Int) {
        let end = location + removed
        let delta = inserted - removed
        if end <= range.lowerBound {
            range = (range.lowerBound + delta) ..< (range.upperBound + delta)
        } else if location >= range.upperBound {
            return
        } else if range.isEmpty {
            // Removed here, and what was around the place is replaced: the place is after what replaced it.
            range = (location + inserted) ..< (location + inserted)
        } else {
            let low = min(range.lowerBound, location)
            range = low ..< max(low, max(range.upperBound, end) + delta)
        }
    }
}
