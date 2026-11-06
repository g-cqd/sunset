/// Which notifications from the program are shown (ADR-0010): only while the window is not focused, and at most one a second. The clock is passed in.
public struct NotificationGate: Sendable {
    private var lastShown: Double?

    public init() {}

    public mutating func admits(atSecond now: Double, windowFocused: Bool) -> Bool {
        guard !windowFocused else { return false }
        if let lastShown, now >= lastShown, now - lastShown < 1 { return false }
        lastShown = now
        return true
    }
}
