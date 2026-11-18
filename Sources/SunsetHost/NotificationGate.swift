/// Which notifications from the program are shown (ADR-0010): only while the window is not focused, and at most one a second. The clock is passed in.
public struct NotificationGate: Sendable {
    private var lastShown: Double?

    public init() {}

    /// Whether the person sees the pane that asked (roadmap 0045 B): it is shown, in the key window, of the app in front.
    /// A pane in a tab not shown, or in a window behind, is not seen though Sunset is in front.
    public static func seen(appActive: Bool, windowKey: Bool, windowVisible: Bool, paneVisible: Bool) -> Bool {
        appActive && windowKey && windowVisible && paneVisible
    }

    public mutating func admits(atSecond now: Double, windowFocused: Bool) -> Bool {
        guard !windowFocused else { return false }
        if let lastShown, now >= lastShown, now - lastShown < 1 { return false }
        lastShown = now
        return true
    }
}
