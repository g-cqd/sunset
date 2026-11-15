import Foundation
import SunsetStorage

/// The history as a file of the person's (R12 step ST-6).
extension HistoryStore {
    /// Every page, the latest first: its address, its title, when it was last visited (ISO 8601) and how many times.
    /// - Complexity: O(pages).
    package func csv() -> String {
        var text = CSV.line(["address", "title", "last visit", "visits"])
        for page in ordered.reversed() where !page.gone {
            let entry = page.entry
            text += CSV.line([entry.url, entry.title, entry.lastVisit.ISO8601Format(), String(entry.visits)])
        }
        return text
    }
}
