@_exported public import AemiRuntime
public import Foundation

/// What a piece of Sunset needs of time and concurrency: where its tasks are spawned, the clock it sleeps on, the monotonic
/// time it measures with, and the wall time. `.live` in the app; a test gives a `TaskProviderSpy`, a `TestClock` (and
/// `uptime: { clock.now.offset }`) and a fixed date, waits for the tasks it started and moves the time itself.
public struct Runtime: Sendable {
    public var tasks: any TaskProvider
    public var clock: any Clock<Duration>
    /// Monotonic time since an arbitrary origin: what a duration, a deadline or an idle time is measured with.
    public var uptime: @Sendable () -> Duration
    /// The wall time, for what is shown or kept as a date.
    public var now: @Sendable () -> Date

    public init(
        tasks: any TaskProvider = LiveTaskProvider(),
        clock: any Clock<Duration> = ContinuousClock(),
        uptime: @escaping @Sendable () -> Duration = { .nanoseconds(LiveClock.monotonicNanoseconds()) },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.tasks = tasks
        self.clock = clock
        self.uptime = uptime
        self.now = now
    }

    /// The app's: real tasks, the continuous clock, the system's monotonic and wall clocks.
    public static let live = Runtime()

    /// Waits `duration` on the clock; false when the task was cancelled meanwhile.
    @discardableResult
    public func sleep(for duration: Duration) async -> Bool {
        do {
            try await clock.sleep(for: duration)
            return true
        } catch {
            return false
        }
    }

    /// Lets the other work of this actor and of the pool run before going on: a long job's turn given up between steps, or
    /// "once what is queued now has run". Not a wait for anything: what has to have happened is waited for as itself.
    public func yieldTurn() async {
        await Task.yield()
    }

    /// Waits until `deadline` (an `uptime()`); false when the task was cancelled meanwhile.
    @discardableResult
    public func sleep(until deadline: Duration) async -> Bool {
        await sleep(for: max(.zero, deadline - uptime()))
    }

    /// Runs `operation` in a task of the provider's (`role`: `.observation` for a loop that runs as long as its owner).
    /// As `Task { }`: its actor, and `self` without being named, are the caller's.
    @discardableResult
    public func task<Success: Sendable>(
        role: TaskRole = .work,
        priority: TaskPriority? = nil,
        @_inheritActorContext @_implicitSelfCapture _ operation: sending @escaping @isolated(any) () async -> Success
    ) -> Task<Success, Never> {
        tasks.task(role: role, priority: priority, operation: operation)
    }

    /// Runs `operation` in a task of its own, apart from the caller's actor (on `executorPreference`, a dedicated thread,
    /// when given): for work that must not run where it was asked, as reading a terminal's output or encoding a frame.
    @discardableResult
    public func detached<Success: Sendable>(
        executorPreference: (any TaskExecutor)? = nil,
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ operation: sending @escaping () async -> Success
    ) -> Task<Success, Never> {
        Task.detached(executorPreference: executorPreference, priority: priority, operation: operation)
    }
}
