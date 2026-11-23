package import CoreGraphics

/// A press that may open the menu a right click would (n112): held `hold` without moving more than `slop` points, or
/// pressed deep on a Force Touch trackpad; one menu a press, none once it moved, ended or opened one.
package struct LongPress: Equatable, Sendable {
    /// How long a press is held for its menu, as iPadOS's.
    package static let hold: Duration = .milliseconds(500)
    /// How far a hand may tremble and still hold still.
    package static let slop = 5.0

    private let start: CGPoint
    private let time: Duration
    private var live = true

    /// A press at `start`, at `time` (the runtime's uptime).
    package init(at start: CGPoint, time: Duration) {
        self.start = start
        self.time = time
    }

    package mutating func moved(to point: CGPoint) {
        if hypot(point.x - start.x, point.y - start.y) > Self.slop { live = false }
    }

    package mutating func end() {
        live = false
    }

    /// Whether its menu opens now, by holding: true once.
    package mutating func isDue(at now: Duration) -> Bool {
        guard live, now - time >= Self.hold else { return false }
        live = false
        return true
    }

    /// Pressed deep: whether its menu opens (once).
    package mutating func deepPressed() -> Bool {
        guard live else { return false }
        live = false
        return true
    }
}
