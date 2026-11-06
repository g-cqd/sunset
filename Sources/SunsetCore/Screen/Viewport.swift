/// How far a window is scrolled back into the history, and the rules for keeping it there: it stays on the lines it shows while new ones arrive below, never
/// goes past the history's ends, and returns to the live screen when asked.
public struct Viewport: Sendable, Equatable {
    /// Lines above the live screen the window shows (0: the live screen).
    public private(set) var scrolledBack = 0
    private var historyCount = 0

    public init() {}

    public var isLive: Bool { scrolledBack == 0 }

    /// Moves the window by `lines`: positive goes back into the history, negative toward the live screen.
    public mutating func scroll(by lines: Int) {
        scrolledBack = min(max(scrolledBack + lines, 0), historyCount)
    }

    /// Told the history's length with each snapshot. A window scrolled back moves up with the lines it shows when new ones arrive below; one on the live screen
    /// stays there.
    public mutating func follow(historyCount count: Int) {
        if scrolledBack > 0, count > historyCount { scrolledBack += count - historyCount }
        historyCount = count
        scrolledBack = min(scrolledBack, count)
    }

    public mutating func toLive() { scrolledBack = 0 }
}
