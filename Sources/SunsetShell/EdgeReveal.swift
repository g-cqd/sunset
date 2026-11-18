/// When a bar at a window's edge is out (roadmap 0055, the owner's notes n41, n42): always, when it does not hide; else from
/// the pointer reaching the edge until a moment after it leaves the bar, and all the while it is typed in.
package struct EdgeReveal: Equatable, Sendable {
    package var hides: Bool
    package private(set) var reached = false
    package private(set) var over = false
    package var typing = false

    package init(hides: Bool) { self.hides = hides }

    package var isOut: Bool { !hides || reached || over || typing }

    /// The pointer reached the edge's strip.
    package mutating func reachedEdge() { reached = true }

    /// The pointer came over the bar, or left it.
    package mutating func pointer(over: Bool) {
        self.over = over
        if over { reached = true }
    }

    /// The moment after the pointer left has passed: the bar goes unless the pointer is back or it is typed in.
    package mutating func settle() {
        if !over, !typing { reached = false }
    }
}
