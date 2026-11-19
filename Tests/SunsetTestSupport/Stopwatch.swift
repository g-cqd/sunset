/// How long something took, in real time (ADR-0087): for benchmarks, and for tests of how promptly the system answers (a
/// PTY or a file watcher stopping). Sunset's own timing is never measured with it; that is `TestTime`'s.
public struct Stopwatch: Sendable {
    private let clock = ContinuousClock()
    private let start: ContinuousClock.Instant

    public init() {
        start = clock.now
    }

    /// The time since it started.
    public var elapsed: Duration {
        clock.now - start
    }

    /// How long `operation` took.
    public static func time(_ operation: () throws -> Void) rethrows -> Duration {
        let watch = Stopwatch()
        try operation()
        return watch.elapsed
    }
}
