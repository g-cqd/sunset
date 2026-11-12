import Observation

/// Tells the History menu and the history panel to read the history again (a page was visited, an entry deleted, history cleared).
@MainActor @Observable final class HistoryChanges {
    static let shared = HistoryChanges()
    private(set) var generation = 0
    func bump() { generation += 1 }
}
