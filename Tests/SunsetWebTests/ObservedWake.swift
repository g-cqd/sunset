import Foundation

/// A continuation resumed once, by a change or by the test's end, whichever comes first.
final class ObservedWake: @unchecked Sendable {
    private let lock = NSLock()
    private var waiting: CheckedContinuation<Void, Never>?
    private var fired = false

    func set(_ continuation: CheckedContinuation<Void, Never>) {
        lock.lock()
        if fired {
            lock.unlock()
            continuation.resume()
            return
        }
        waiting = continuation
        lock.unlock()
    }

    func fire() {
        lock.lock()
        fired = true
        let continuation = waiting
        waiting = nil
        lock.unlock()
        continuation?.resume()
    }
}
