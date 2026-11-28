package import Foundation

/// A page in the history: one per address, with its last title, how often it was visited and when last.
package struct HistoryEntry: Sendable, Equatable, Identifiable {
    package var url: String
    package var title: String
    package var visits: Int
    package var lastVisit: Date
    /// The profiles it was visited in (their ids), in the order first visited; none for a page kept before they were.
    package var profiles: [String] = []

    package var id: String {
        url
    }

    package init(url: String, title: String, visits: Int, lastVisit: Date, profiles: [String] = []) {
        self.url = url
        self.title = title
        self.visits = visits
        self.lastVisit = lastVisit
        self.profiles = profiles
    }

    /// Whether it was visited in `profile`; a page kept before profiles were noted is every profile's.
    package func isVisited(in profile: String) -> Bool {
        profiles.isEmpty || profiles.contains(profile)
    }

    /// The order of the lists (frecency): visits weighted by how recent the last one is, halving every week.
    package func score(now: Date) -> Double {
        let days = max(now.timeIntervalSince(lastVisit) / 86_400, 0)
        return Double(visits) * pow(0.5, days / 7)
    }
}
