import Synchronization

/// A file's writes (the session's: roadmap 0049), one at a time and the newest last, from any thread (roadmap 0049): a write is numbered when it
/// is asked for; one that comes to the disk after a newer one has been written is dropped, so that a save in the background
/// that starts late never puts an older session over a newer one (a quit's).
public final class NewestWrites: Sendable {
    public init() {}

    private let state = Mutex((asked: 0, written: 0))

    /// The number of the next write.
    public func next() -> Int {
        state.withLock {
            $0.asked += 1
            return $0.asked
        }
    }

    /// Runs `write` as write `turn`, unless a newer one was written; true when the file holds it (or a newer one).
    public func write(_ turn: Int, _ write: () -> Bool) -> Bool {
        state.withLock { counts in
            guard turn > counts.written else { return true }
            guard write() else { return false }
            counts.written = turn
            return true
        }
    }
}
