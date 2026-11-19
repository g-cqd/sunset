/// The person's clicks on a page's notifications, as the page pulls them (task t97: no event of Sunset's on its window, which
/// any script could fire or hear): one pull waits at a time; clicks made while none waits are kept, in order, a few at most.
@MainActor
final class NotificationClicks {
    private var waiting: CheckedContinuation<Int?, Never>?
    private var kept: [Int] = []
    static let most = 16

    /// The next click's notification id; nil when another pull replaces this one, or the page ends.
    func next() async -> Int? {
        if !kept.isEmpty { return kept.removeFirst() }
        waiting?.resume(returning: nil)
        return await withCheckedContinuation { waiting = $0 }
    }

    func clicked(_ id: Int) {
        if let pull = waiting {
            waiting = nil
            pull.resume(returning: id)
        } else if kept.count < Self.most {
            kept.append(id)
        }
    }

    /// The page ended: its pull is answered with nothing.
    func end() {
        kept = []
        waiting?.resume(returning: nil)
        waiting = nil
    }
}
