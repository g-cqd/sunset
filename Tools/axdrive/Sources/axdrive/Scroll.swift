import CoreGraphics

/// A scroll wheel turned over a point of the app's main window (`CGEvent.postToPid`): the view under the point scrolls, without the
/// app being brought to the front. X and Y are points from the window's top-left corner; positive DY moves the content up (as when
/// the wheel brings later content into view).
enum Scroll {
    static func wheel(_ words: [String], pid: pid_t) -> Bool {
        guard words.count >= 3, let x = Double(words[0]), let y = Double(words[1]), let delta = Int32(words[2]),
            let window = mainWindow(pid)
        else { return false }
        let point = CGPoint(x: window.bounds.minX + x, y: window.bounds.minY + y)
        // In steps of at most 40 points, as a wheel sends them, so the view follows each one.
        var left = delta
        while left != 0 {
            let step = left > 0 ? min(left, 40) : max(left, -40)
            guard
                let event = CGEvent(
                    scrollWheelEvent2Source: nil,
                    units: .pixel,
                    wheelCount: 1,
                    wheel1: -step,
                    wheel2: 0,
                    wheel3: 0
                )
            else { return false }
            event.location = point
            event.postToPid(pid)
            left -= step
            usleep(16_000)
        }
        return true
    }

    /// The pointer moved to a point of the window, for that process only (the real pointer does not move).
    static func hover(_ words: [String], pid: pid_t) -> Bool {
        guard words.count >= 2, let x = Double(words[0]), let y = Double(words[1]),
            let window = mainWindow(pid),
            let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: CGPoint(x: window.bounds.minX + x, y: window.bounds.minY + y),
                mouseButton: .left
            )
        else { return false }
        event.postToPid(pid)
        return true
    }

    /// The app's largest window: the first one listed can be a hidden helper (a 500 by 500 window off to the side).
    private static func mainWindow(_ pid: pid_t) -> (id: Int, title: String, bounds: CGRect)? {
        Capture.windows(pid: pid).max { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height }
    }
}
