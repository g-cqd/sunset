import Foundation
import Testing

@testable import SunsetWeb

@Suite("The history of pages") @MainActor struct HistoryStoreTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    func day(_ days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }

    @Test func `a visit is counted once per address, keeping the last title and time`() throws {
        let store = try #require(HistoryStore(path: ":memory:"))
        store.visit("https://a.com/", title: "A", at: day(2))
        store.visit("https://a.com/", title: "", at: day(1))
        store.retitle("https://a.com/", title: "A page")
        let entry = try #require(store.entries().first)
        #expect(entry.visits == 2 && entry.title == "A page" && entry.lastVisit == day(1))
    }

    @Test func `suggestions put a host or title that starts with the text first, then frecency`() throws {
        let store = try #require(HistoryStore(path: ":memory:"))
        for _ in 0 ..< 5 { store.visit("https://docs.example.com/swift", title: "Docs", at: day(1)) }
        store.visit("https://www.swift.org/", title: "Swift.org", at: day(30))
        store.visit("https://old.com/swift", title: "Old", at: day(60))
        let found = store.suggestions(for: "swift", now: now).map(\.url)
        #expect(found.first == "https://www.swift.org/" && found.count == 3)
        #expect(found[1] == "https://docs.example.com/swift")
    }

    @Test func `clearing a span and expiring old pages`() throws {
        let store = try #require(HistoryStore(path: ":memory:"))
        store.visit("https://new.com/", title: "", at: day(0.01))
        store.visit("https://week.com/", title: "", at: day(6))
        store.visit("https://year.com/", title: "", at: day(400))
        store.clear(since: day(1))
        store.expire(before: day(365))
        #expect(store.entries().map(\.url) == ["https://week.com/"])
        store.delete("https://week.com/")
        #expect(store.entries().isEmpty)
    }

    @Test func `the file keeps the history across opens`() throws {
        let path = NSTemporaryDirectory() + "history-\(UUID().uuidString).sqlite"
        do {
            let store = try #require(HistoryStore(path: path))
            store.visit("https://kept.com/", title: "Kept")
        }
        #expect(HistoryStore(path: path)?.entries().first?.title == "Kept")
    }
}
