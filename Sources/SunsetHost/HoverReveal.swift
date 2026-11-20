/// Something that shows while the pointer is over a strip (or over what the strip revealed) and goes a moment after it leaves, so that a pointer that
/// drifts out for an instant does not make it flicker. Pure: the caller gives it the time and, when `hidesAt` is set, looks again then.
public struct HoverReveal: Sendable, Equatable {
    public var hideDelay: Duration
    private var inside = false
    private var leftAt: Duration?
    private var everEntered = false
    private var held = false

    public init(hideDelay: Duration) {
        self.hideDelay = hideDelay
    }

    /// The pointer is over the strip or the revealed panel, or is not.
    public mutating func pointer(inside now: Bool, at time: Duration) {
        if now {
            inside = true
            leftAt = nil
            everEntered = true
        } else if inside {
            inside = false
            leftAt = time
        }
    }

    /// Held out whatever the pointer does (a field in it is typed in); let go, it goes after the delay unless the pointer is inside.
    public mutating func hold(_ now: Bool, at time: Duration) {
        guard now != held else { return }
        held = now
        if !now, !inside {
            leftAt = time
            everEntered = true
        }
    }

    public func isShown(at time: Duration) -> Bool {
        if inside || held { return true }
        guard everEntered, let leftAt else { return false }
        return time < leftAt + hideDelay
    }

    /// When to look again: the moment it hides, or nil when it is not waiting to hide.
    public var hidesAt: Duration? {
        held ? nil : leftAt.map { $0 + hideDelay }
    }
}
