import Foundation
import SunsetStorage

/// What the history holds in memory for each page, and how a page is read from its kept record.
extension HistoryStore {
    /// A page, and its address and title as one run of bytes with plain letters in lower case: what a search looks through.
    final class Page {
        var entry: HistoryEntry
        var hay: [UInt8]
        /// Visited again since, or deleted: another page of the list stands for it, or none.
        var gone = false

        init(_ entry: HistoryEntry) {
            self.entry = entry
            hay = HistoryStore.folded(Array((entry.url + "\n" + entry.title).utf8))
        }

        init(_ kept: Kept) {
            entry = kept.entry
            hay = kept.hay
        }
    }

    /// A page as read from its kept record: made off the main actor, on several threads, when the history is opened. A class,
    /// so that the thousands of them are passed along by reference, not copied.
    final class Kept: Sendable {
        let entry: HistoryEntry
        let hay: [UInt8]

        /// The record's bytes are the address, a line break and the title.
        init?(_ row: SealedTable.Row) {
            guard let line = row.payload.firstIndex(of: 10) else { return nil }
            entry = HistoryEntry(
                url: String(decoding: row.payload[..<line], as: UTF8.self),
                title: String(decoding: row.payload[(line + 1)...], as: UTF8.self),
                visits: row.count,
                lastVisit: Date(timeIntervalSince1970: row.sort)
            )
            hay = HistoryStore.folded(Array(row.payload))
        }
    }

    /// What was taken out while a large history was still being read: applied to what the reading brings.
    struct Removed {
        var addresses: Set<String> = []
        var since: Date?
        var before: Date?

        func covers(_ entry: HistoryEntry) -> Bool {
            addresses.contains(entry.url) || since.map { entry.lastVisit >= $0 } ?? false
                || before.map { entry.lastVisit < $0 } ?? false
        }
    }
}
