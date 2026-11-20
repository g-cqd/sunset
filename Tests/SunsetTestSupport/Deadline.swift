import AemiTestKit

/// An answer that may never come, given up at a deadline (ADR-0087): the next event of a stream, a reply, a task's end.
/// The operation and the deadline race; the loser is cancelled. The deadline is the harness's own timer: a `TestClock`
/// does not count it among the sleepers a test waits for.
public enum Deadline {
    /// What `operation` returns, or nil once `limit` has passed on `clock`.
    public static func first<Value: Sendable, C: Clock>(
        within limit: C.Duration,
        clock: C,
        _ operation: @escaping @Sendable () async throws -> Value
    ) async rethrows -> Value? {
        try await withThrowingTaskGroup(of: Value?.self) { group in
            group.addTask { try await operation() }
            TestClock.withUntrackedSleeps {
                group.addTask {
                    try? await clock.sleep(for: limit)
                    return nil
                }
            }
            defer { group.cancelAll() }
            return try await group.next() ?? nil
        }
    }

    /// On the wall clock.
    public static func first<Value: Sendable>(
        within limit: Duration,
        _ operation: @escaping @Sendable () async throws -> Value
    ) async rethrows -> Value? {
        try await first(within: limit, clock: ContinuousClock(), operation)
    }
}
