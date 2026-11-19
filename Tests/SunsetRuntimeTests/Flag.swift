import Synchronization

/// A flag set from a task.
final class Flag: Sendable {
    private let state = Mutex(false)

    var value: Bool {
        state.withLock { $0 }
    }

    func set() {
        state.withLock { $0 = true }
    }
}
