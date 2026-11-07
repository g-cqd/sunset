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

    public func blinks(afterIdle idle: Duration, focused: Bool = true) -> Bool {
        focused && (stopAfter.map { idle < $0 } ?? true)
    }

    /// How long to wait before looking again; nil when nothing needs a timer (the cursor is solid: the next activity or the focus coming back wakes the
    /// caller, so an idle or hidden terminal does not wake up at all).
    public func wait(afterIdle idle: Duration, focused: Bool = true) -> Duration? {
        blinks(afterIdle: idle, focused: focused) ? interval : nil
    }
}
