import Synchronization

/// Raised once a change is noticed, from whichever thread notices it.
final class ChangeFlag: Sendable {
    private let raised = Mutex(false)
    var isRaised: Bool { raised.withLock { $0 } }
    func raise() { raised.withLock { $0 = true } }
}
