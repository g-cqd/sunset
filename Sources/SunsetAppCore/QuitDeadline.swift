package import SunsetRuntime

/// The quit's last work awaited, at most its limit. It was waited for by spinning the run loop: from inside a main-actor
/// task (the quit asks first, `QuitGate.decide`) a main-actor task cannot start, so the work never ran and the limit
/// always passed. Here the work and a timer race; nothing spins.
@MainActor
package enum QuitDeadline {
    /// True when `work` ended before `limit`; false when the limit passed first (the work is left to go on).
    @discardableResult
    package static func wait(limit: Duration, runtime: Runtime, _ work: @escaping @MainActor () async -> Void) async
        -> Bool
    {
        let race = Race()
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            race.continuation = continuation
            race.timer = runtime.task { @MainActor in
                await runtime.sleep(for: limit)
                race.end(false)
            }
            runtime.task { @MainActor in
                await work()
                race.end(true)
            }
        }
    }

    /// The first of the work and the timer to end answers; the timer is stopped when the work wins.
    private final class Race {
        var continuation: CheckedContinuation<Bool, Never>?
        var timer: Task<Void, Never>?

        func end(_ finished: Bool) {
            guard let continuation else { return }
            self.continuation = nil
            if finished { timer?.cancel() }
            continuation.resume(returning: finished)
        }
    }
}
