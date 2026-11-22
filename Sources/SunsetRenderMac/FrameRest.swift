public import SunsetRuntime

/// Tells a terminal's renderer to rest once no frame has been drawn for a while: a terminal that is quiet, or not shown, then keeps the one surface on screen instead of two or three. One waiting
/// task however many frames are drawn; it looks at the time of the last frame when it wakes.
@MainActor
public final class FrameRest {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    public var runtime = Runtime.live

    /// How long without a frame. Longer than a blinking cursor's half-second, so that a focused terminal's surfaces are not
    /// let go and made again at each blink.
    public static let usual = Duration.seconds(2)
    /// How many times a renderer that could not let everything go is asked (the window server holds the surface shown
    /// before for a moment after a frame).
    static let tries = 4

    private let after: Duration
    /// When the last frame was drawn, or the renderer last asked.
    private var since: Duration
    private var waiting: Task<Void, Never>?
    private var stopped = false

    public init(after: Duration = FrameRest.usual, runtime: Runtime = .live) {
        self.after = after
        self.runtime = runtime
        since = runtime.uptime()
    }

    /// A frame was drawn: `rest` runs once none has followed for the delay, and again while it says there is more to let go.
    public func frameDrawn(rest: @escaping @MainActor () async -> Bool) {
        since = runtime.uptime()
        if waiting == nil { wait(rest, triesLeft: Self.tries) }
    }

    private func wait(_ rest: @escaping @MainActor () async -> Bool, triesLeft: Int) {
        waiting = runtime.task { [weak self, runtime] in
            while let left = self?.left, left > .zero {
                await runtime.sleep(for: left)
                if Task.isCancelled { return }
            }
            guard let self, !Task.isCancelled else { return }
            // Not waiting any more: a frame drawn while the renderer rests starts the wait again by itself.
            self.waiting = nil
            let done = await rest()
            guard !done, triesLeft > 1, self.waiting == nil, !self.stopped else { return }
            self.since = self.runtime.uptime()
            self.wait(rest, triesLeft: triesLeft - 1)
        }
    }

    /// The terminal is going away: nothing more is told.
    public func cancel() {
        stopped = true
        waiting?.cancel()
        waiting = nil
    }

    /// How long until the delay is over.
    private var left: Duration {
        after - (runtime.uptime() - since)
    }
}
