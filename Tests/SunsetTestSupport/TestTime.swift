public import AemiTestKit
public import Foundation
public import SunsetRuntime
import Testing

/// The time and the tasks of what a test runs: a `TestClock` nothing passes on but the test's word, a `TaskProviderSpy`
/// that knows every task started, and the `Runtime` made of them for the code under test.
public final class TestTime: Sendable {
    public let clock = TestClock()
    public let spy = TaskProviderSpy()
    public let runtime: Runtime

    /// How long a test waits, in real time, before it says a task never ended: a guard, not a timing.
    public static let guardTime = Duration.seconds(5)

    /// The wall time a test runs at unless it says another: fixed, so that ages and expiries are the same on every run.
    public static let epoch = Date(timeIntervalSince1970: 1_800_000_000)

    public init(now: Date = TestTime.epoch) {
        let clock = clock
        runtime = Runtime(tasks: spy, clock: clock, uptime: { clock.now.offset }, now: { now })
    }

    /// Before an action that waits on the clock: what it registers is counted from here.
    public func mark() -> TestClock.RegistrationMark {
        clock.registrationMark()
    }

    /// The `count` waits the action since `mark` started on the clock end `duration` later; every task then settles.
    public func release(after duration: Duration, since mark: TestClock.RegistrationMark, count: Int = 1) async throws {
        try await waited(since: mark, count: count)
        clock.advance(by: duration)
        try await settle()
    }

    /// The action since `mark` has started its wait on the clock; a test fails, it does not hang, when none begins within
    /// `guardTime` of real time.
    public func waited(since mark: TestClock.RegistrationMark, count: Int = 1) async throws {
        let clock = clock
        try await Self.guarded("\(count) wait(s) did not begin on the test clock") {
            try await clock.waitForSleepers(count, after: mark)
        }
    }

    /// No wait began, or no task ended, within `guardTime`.
    public struct Stalled: Error, CustomStringConvertible {
        public let description: String
    }

    /// `operation`, or `Stalled` once `guardTime` of real time has passed.
    static func guarded(_ what: String, _ operation: @escaping @Sendable () async throws -> Void) async throws {
        guard try await withDeadline(within: guardTime, operation) != nil else {
            throw Stalled(description: what)
        }
    }

    /// Every task started has ended (long-lived loops, `.observation`, aside).
    public func settle() async throws {
        try await spy.waitForAllTasks(timeout: Self.guardTime)
    }

    /// The clock moves on by `duration`; no wait ends in it.
    public func advance(_ duration: Duration) {
        clock.advance(by: duration)
    }

    /// `duration` passes, a wait ends in it, and its task waits again: back once that new wait has begun.
    public func passStillWaiting(_ duration: Duration) async throws {
        let mark = mark()
        clock.advance(by: duration)
        try await waited(since: mark)
    }

    /// `duration` passes, and the long-lived loops (`.observation`) that end with it have ended.
    public func passToEnd(_ duration: Duration) async throws {
        clock.advance(by: duration)
        try await spy.waitForObservationsToFinish(timeout: Self.guardTime)
        try await settle()
    }

    /// `duration` passes; what waited for less wakes, and every task settles.
    public func pass(_ duration: Duration) async throws {
        clock.advance(by: duration)
        try await settle()
    }
}
