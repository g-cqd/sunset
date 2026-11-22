package import Foundation
import SunsetRuntime

/// Looking through the history in memory: its pages hold their address and title as bytes with plain letters in lower case.
extension HistoryStore {
    /// The pages whose address or title holds `text` (all when empty), latest first, at most `limit`. Plain letters match
    /// whatever their case.
    /// - Complexity: O(the history's bytes) at worst; it stops at `limit` pages.
    package func entries(matching text: String = "", limit: Int = 500) -> [HistoryEntry] {
        let needle = Self.folded(Array(text.utf8))
        var found: [HistoryEntry] = []
        for page in ordered.reversed() where !page.gone && Self.holds(page.hay, needle) {
            found.append(page.entry)
            if found.count >= limit { break }
        }
        return found
    }

    /// The best matches for what is typed in an address field: by frecency, those whose host or title starts with it first.
    package func suggestions(for text: String, limit: Int = 4, now: Date = Runtime.live.now()) -> [HistoryEntry] {
        let typed = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !typed.isEmpty else { return [] }
        let found = entries(matching: typed, limit: 200)
        func prefix(_ entry: HistoryEntry) -> Bool {
            let host = URL(string: entry.url)?.host()?.lowercased() ?? ""
            let bare = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            return bare.hasPrefix(typed) || host.hasPrefix(typed) || entry.title.lowercased().hasPrefix(typed)
        }
        return Array(
            found.sorted { left, right in
                let (l, r) = (prefix(left), prefix(right))
                return l != r ? l : left.score(now: now) > right.score(now: now)
            }
            .prefix(limit)
        )
    }

    /// The last `limit` pages visited.
    package func recent(limit: Int = 10) -> [HistoryEntry] {
        entries(limit: limit)
    }

    /// The bytes of `text`, plain capital letters made small: what SQLite's `LIKE` did for the history before.
    package nonisolated static func folded(_ text: [UInt8]) -> [UInt8] {
        var bytes = text
        for index in bytes.indices where bytes[index] >= 65 && bytes[index] <= 90 { bytes[index] += 32 }
        return bytes
    }

    package static func holds(_ hay: [UInt8], _ needle: [UInt8]) -> Bool {
        guard !needle.isEmpty else { return true }
        return hay.withUnsafeBytes { hay in
            needle.withUnsafeBytes { needle in
                unsafe memmem(hay.baseAddress, hay.count, needle.baseAddress, needle.count) != nil
            }
        }
    }
}

extension HistoryStore {
    /// The title `url` was last seen with; nil when it was never seen, or seen with none (a page not loaded in this run
    /// is named by it).
    package func title(of url: String) -> String? {
        guard let page = byAddress[url], !page.gone, !page.entry.title.isEmpty else {
            return nil
        }
        return page.entry.title
    }
}
