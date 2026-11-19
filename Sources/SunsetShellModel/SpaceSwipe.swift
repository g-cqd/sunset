/// The two-finger swipe on the sidebar that changes Space (roadmap 0021 step S-b), as numbers: what the trackpad says goes
/// in, what the list does comes out. The owner, 2026-11-17: the list follows the fingers, "starting slow and snap when
/// enough swiped, not swipe multiple ones at the same time".
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
        /// Of a gesture that already changed Space: nothing.
        case consumed
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
    ///   - canGo: whether there is a Space before, and one after.
    /// - Returns: what the list does.
    package mutating func move(dx: Double, dy: Double, width: Double, canGo: (previous: Bool, next: Bool)) -> Step {
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
        guard towardsNext ? canGo.next : canGo.previous else {
            // No Space that way: the list gives a little and no more.
            let give = width * 0.12 * (1 - Self.decay(distance / max(width, 1)))
            offset = towardsNext ? -give : give
            return .follow
        }
        if distance >= width * Self.threshold {
            // The list is left where the fingers had it: the slide to the other Space goes on from there.
            phase = .done
            return .snap(towardsNext ? 1 : -1)
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

    /// 1 at 0, towards 0 as `part` grows: 1 / (1 + 3x).
    private static func decay(_ part: Double) -> Double {
        1 / (1 + 3 * max(part, 0))
    }
}
