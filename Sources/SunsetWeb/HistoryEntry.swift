package import Foundation

/// A page in the history (web step e): one per address, with its last title, how often it was visited and when last.
package struct HistoryEntry: Sendable, Equatable, Identifiable {
    package var url: String
    package var title: String
    package var visits: Int
    package var lastVisit: Date

    package var id: String { url }

    package init(url: String, title: String, visits: Int, lastVisit: Date) {
        self.url = url
        self.title = title
        self.visits = visits
        self.lastVisit = lastVisit
    }

    /// The order of the lists (frecency): visits weighted by how recent the last one is, halving every week.
    package func score(now: Date) -> Double {
        let days = max(now.timeIntervalSince(lastVisit) / 86_400, 0)
        return Double(visits) * pow(0.5, days / 7)
    }
}
