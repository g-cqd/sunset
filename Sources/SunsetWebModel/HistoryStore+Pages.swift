package import Foundation
package import SunsetStorage

/// What the history holds in memory for each page, and how a page is read from its kept record.
extension HistoryStore {
    /// A page, and its address and title as one run of bytes with plain letters in lower case: what a search looks through.
    package final class Page {
        package var entry: HistoryEntry
        package var hay: [UInt8]
        /// Visited again since, or deleted: another page of the list stands for it, or none.
        package var gone = false

        package init(_ entry: HistoryEntry) {
            self.entry = entry
            hay = HistoryStore.folded(Array((entry.url + "\n" + entry.title).utf8))
        }

        package init(_ kept: Kept) {
            entry = kept.entry
            hay = kept.hay
        }
    }

    /// A page as read from its kept record: made off the main actor, on several threads, when the history is opened. A class,
    /// so that the thousands of them are passed along by reference, not copied.
    package final class Kept: Sendable {
        package let entry: HistoryEntry
        package let hay: [UInt8]

        /// The record's bytes are the address, a line break and the title; then, when the page has them, a unit separator
        /// and the ids of the profiles it was visited in, comma-separated.
        package init?(_ row: SealedTable.Row) {
            guard let line = row.payload.firstIndex(of: 10) else { return nil }
            let rest = row.payload[(line + 1)...]
            let unit = rest.firstIndex(of: 0x1F)
            let title = rest[..<(unit ?? rest.endIndex)]
            let profiles = unit.map { String(decoding: rest[($0 + 1)...], as: UTF8.self) } ?? ""
            entry = HistoryEntry(
                url: String(decoding: row.payload[..<line], as: UTF8.self),
                title: String(decoding: title, as: UTF8.self),
                visits: row.count,
                lastVisit: Date(timeIntervalSince1970: row.sort),
                profiles: profiles.split(separator: ",").map(String.init)
            )
            hay = HistoryStore.folded(Array(row.payload[..<(unit ?? row.payload.endIndex)]))
        }
    }

    /// What was taken out while a large history was still being read: applied to what the reading brings.
    package struct Removed {
        package var addresses: Set<String> = []
        package var since: Date?
        package var before: Date?

        package func covers(_ entry: HistoryEntry) -> Bool {
            addresses.contains(entry.url) || since.map { entry.lastVisit >= $0 } ?? false
                || before.map { entry.lastVisit < $0 } ?? false
        }
    }
}
