public import Testing

/// Waiting for a state that announces nothing (ADR-0087): a view laid out, a listener's port, a server's log. The condition
/// is looked at again every `interval` on `clock` until it holds; past `limit`, the wait throws, naming what it waited for
/// and where. Prefer an event when there is one: `waitForObservedState` for an `@Observable` model, `KeyValueProbe` for a
/// key-value observable property, an `AsyncEventProbe` recorded by the code; polling is for what has none.
public enum Poll {
    /// The condition still did not hold when the limit passed.
    public struct Timeout: Error, CustomStringConvertible {
        public let label: String
        public let limit: String
        public let sourceLocation: SourceLocation

        public var description: String {
            "\(label.isEmpty ? "the condition" : label) did not hold within \(limit) (waited at \(sourceLocation))"
        }
    }

    /// Looks at `condition` until it holds, every `interval` on `clock`; throws `Timeout` once `limit` has passed, and
    /// `CancellationError` when the task is cancelled. On a `TestClock` the looks are the test's to advance.
    public static func until<C: Clock>(
        _ label: String = "",
        within limit: C.Duration,
        every interval: C.Duration,
        clock: C,
        isolation: isolated (any Actor)? = #isolation,
        sourceLocation: SourceLocation = #_sourceLocation,
        _ condition: () async throws -> Bool
    ) async throws {
        let deadline = clock.now.advanced(by: limit)
        while try await !condition() {
            guard clock.now < deadline else {
                throw Timeout(label: label, limit: "\(limit)", sourceLocation: sourceLocation)
            }
            try await clock.sleep(for: interval)
        }
    }

    /// On the wall clock, every 10 ms, for at most `limit`: a hang guard, not a latency assertion.
    public static func until(
        _ label: String = "",
        within limit: Duration = .seconds(10),
        every interval: Duration = .milliseconds(10),
        isolation: isolated (any Actor)? = #isolation,
        sourceLocation: SourceLocation = #_sourceLocation,
        _ condition: () async throws -> Bool
    ) async throws {
        try await until(
            label,
            within: limit,
            every: interval,
            clock: ContinuousClock(),
            sourceLocation: sourceLocation,
            condition
        )
    }
}
