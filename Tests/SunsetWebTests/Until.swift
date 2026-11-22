import Foundation
import Observation

/// Waits for `condition`, as changes of what it reads (no sleep, no clock); gives up when the test's time is up.
@MainActor
func until(_ condition: @escaping @MainActor () -> Bool) async {
    while !condition(), !Task.isCancelled {
        let wake = ObservedWake()
        await withTaskCancellationHandler {
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                wake.set(done)
                withObservationTracking {
                    _ = condition()
                } onChange: {
                    wake.fire()
                }
            }
        } onCancel: {
            wake.fire()
        }
    }
}
