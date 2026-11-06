/// When the cursor blinks. It stops after a while without input or output (an idle terminal then does no work at all: every blink is a frame and several
/// wakeups) and starts again with the next activity.
public struct BlinkSchedule: Sendable, Equatable {
    public var interval: Duration
    /// The idle time after which the cursor stays solid; nil to blink forever.
    public var stopAfter: Duration?

    public init(interval: Duration = .milliseconds(550), stopAfter: Duration? = .seconds(15)) {
        self.interval = interval
        self.stopAfter = stopAfter
    }

    public func blinks(afterIdle idle: Duration) -> Bool { stopAfter.map { idle < $0 } ?? true }

    /// How long to wait before looking again.
    public func wait(afterIdle idle: Duration) -> Duration { blinks(afterIdle: idle) ? interval : .seconds(2) }
}
