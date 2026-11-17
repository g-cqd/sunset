import Foundation
import Observation

/// Waiting in a test for what an observable model says (white paper §1: no sleeps, no polling).
@MainActor
enum Waiting {
    /// Waits for `condition`, looking again each time what it reads changes; given up when the test is cancelled (its
    /// time limit), so that a regression fails instead of hanging.
    static func until(_ condition: @escaping @MainActor () -> Bool) async {
        final class Once: @unchecked Sendable {
            // Touched on the main actor only.
            var resume: (() -> Void)?
        }
        while !condition(), !Task.isCancelled {
            let once = Once()
            await withTaskCancellationHandler {
                await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                    once.resume = { done.resume() }
                    withObservationTracking {
                        _ = condition()
                    } onChange: {
                        Task { @MainActor in
                            once.resume?()
                            once.resume = nil
                        }
                    }
                }
            } onCancel: {
                Task { @MainActor in
                    once.resume?()
                    once.resume = nil
                }
            }
        }
    }
}
