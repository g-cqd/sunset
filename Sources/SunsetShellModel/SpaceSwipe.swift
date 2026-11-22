/// The two-finger swipe on the sidebar that changes Space, as numbers: what the trackpad says goes in, what the list
/// does comes out. The list follows the fingers, slowly at first, then snaps to the next Space once swiped far enough,
/// one Space at a time.
///
/// A gesture is the list's or this one's from its start, by the direction it starts in. Sideways, the list moves less
/// than the fingers at first and more as they go; at `threshold` of the sidebar's width it snaps to the neighbour, once: the
/// rest of the gesture, and the momentum the trackpad sends after it, change nothing.
package struct SpaceSwipe: Equatable {
    package enum Step: Equatable {
        /// The list's: it scrolls as if this were not here.
        case scroll
        /// The list is `offset` from its place.
        case follow
        /// Enough was swiped: the Space is the next (1) or the previous (-1) now.
        case snap(Int)
        /// Enough was swiped past the last Space on the sidebar's side: the Library opens.
        case library
        /// Of a gesture that already changed Space: nothing.
        case consumed
    }

    /// What a side holds: another Space, the Library (past the last Space on the sidebar's side), or nothing.
    package enum Way: Equatable, Sendable { case space, library, nothing }

    /// Where the Library is to swipe to: past the first Space (`previous`, a sidebar on the left) or the last (`next`).
    package enum LibrarySide: Equatable, Sendable { case previous, next }

    /// What each side of the Space at `index` of `count` holds.
    package static func ways(index: Int, count: Int, library: LibrarySide?, libraryOpen: Bool = false)
        -> (previous: Way, next: Way)
    {
        // With the Library open, the way back to the tabs only: opposite to the way in.
        if libraryOpen { return (library == .next ? .library : .nothing, library == .previous ? .library : .nothing) }
        return (
            index > 0 ? .space : (library == .previous ? .library : .nothing),
            index < count - 1 ? .space : (library == .next ? .library : .nothing)
        )
    }

    /// Whether the swipe is listened to: only if there is somewhere to go. With the Library open, the Spaces are not shown:
    /// only for the way back to the tabs.
    package static func listens(libraryOpen: Bool, spaces: Int, library: LibrarySide?) -> Bool {
        libraryOpen ? library != nil : spaces > 1 || library != nil
    }

    /// How far the fingers go, as a part of the sidebar's width, before the Space changes.
    package static let threshold = 0.3

    private enum Phase { case idle, undecided, scrolling, following, done }

    /// Where the list is drawn, in points from its place (negative: towards the next Space).
    package private(set) var offset = 0.0
    private var phase = Phase.idle
    private var travelled = (x: 0.0, y: 0.0)

    package init() {}

    package static func == (first: SpaceSwipe, second: SpaceSwipe) -> Bool {
        first.offset == second.offset && first.phase == second.phase
    }

    /// Fingers came down.
    package mutating func begin() {
        phase = .undecided
        travelled = (0, 0)
        offset = 0
    }

    /// The fingers moved by `dx`, `dy` points (negative `dx`: to the left, towards the next Space).
    /// - Parameters:
    ///   - dx: the move sideways.
    ///   - dy: the move up or down.
    ///   - width: the sidebar's width.
    ///   - ways: what is before, and after.
    /// - Returns: what the list does.
    package mutating func move(dx: Double, dy: Double, width: Double, ways: (previous: Way, next: Way)) -> Step {
        switch phase {
            case .idle, .scrolling: return .scroll
            case .done: return .consumed
            case .undecided:
                travelled.x += dx
                travelled.y += dy
                // Too little to tell yet: the list's, as a scroll that starts is.
                guard abs(travelled.x) + abs(travelled.y) >= 2 else { return .scroll }
                guard abs(travelled.x) > abs(travelled.y) else {
                    phase = .scrolling
                    return .scroll
                }
                phase = .following
            case .following: travelled.x += dx
        }
        let distance = abs(travelled.x)
        let towardsNext = travelled.x < 0
        let way = towardsNext ? ways.next : ways.previous
        guard way != .nothing else {
            // Nothing that way: the gesture is the list's, as one up or down is.
            phase = .scrolling
            offset = 0
            return .scroll
        }
        if distance >= width * Self.threshold {
            // The list is left where the fingers had it: the slide to the other Space goes on from there.
            phase = .done
            return way == .library ? .library : .snap(towardsNext ? 1 : -1)
        }
        // Slow at first, then with the fingers: a part of the width, raised.
        let eased = width * Self.raised(distance / max(width, 1))
        offset = towardsNext ? -eased : eased
        return .follow
    }

    /// Fingers went up: the list goes back to its place (a snap, if there was one, was said when it happened).
    @discardableResult
    package mutating func end() -> Int? {
        phase = .idle
        offset = 0
        return nil
    }

    /// Between x and x squared on 0...1: three tenths of the fingers' speed at the start, level with them at 1.
    private static func raised(_ part: Double) -> Double {
        let clamped = min(max(part, 0), 1)
        return clamped * (0.3 + 0.7 * clamped)
    }
}
