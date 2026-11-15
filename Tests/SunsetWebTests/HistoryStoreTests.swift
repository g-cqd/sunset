import Foundation
import Testing

@testable import SunsetWeb

@Suite("The history of pages") @MainActor struct HistoryStoreTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    func day(_ days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }

    @Test func `a visit is counted once per address, keeping the last title and time`() throws {
        let store = HistoryStore()
        store.visit("https://a.com/", title: "A", at: day(2))
        store.visit("https://a.com/", title: "", at: day(1))
        store.retitle("https://a.com/", title: "A page")
        let entry = try #require(store.entries().first)
        #expect(entry.visits == 2 && entry.title == "A page" && entry.lastVisit == day(1))
    }

    @Test func `suggestions put a host or title that starts with the text first, then frecency`() throws {
        let store = HistoryStore()
        for _ in 0 ..< 5 { store.visit("https://docs.example.com/swift", title: "Docs", at: day(1)) }
        store.visit("https://www.swift.org/", title: "Swift.org", at: day(30))
        store.visit("https://old.com/swift", title: "Old", at: day(60))
        let found = store.suggestions(for: "swift", now: now).map(\.url)
        #expect(found.first == "https://www.swift.org/" && found.count == 3)
        #expect(found[1] == "https://docs.example.com/swift")
    }

    @Test func `clearing a span and expiring old pages`() throws {
        let store = HistoryStore()
        store.visit("https://new.com/", title: "", at: day(0.01))
        store.visit("https://week.com/", title: "", at: day(6))
        store.visit("https://year.com/", title: "", at: day(400))
        store.clear(since: day(1))
        store.expire(before: day(365))
        #expect(store.entries().map(\.url) == ["https://week.com/"])
        store.delete("https://week.com/")
        #expect(store.entries().isEmpty)
    }

    @Test func `the sealed records keep the history across opens, with its counts, titles and order`() throws {
        let path = NSTemporaryDirectory() + "history-\(UUID().uuidString)/state.sqlite"
        do {
            let store = HistoryStore(table: try TestState.table("history", at: path))
            store.visit("https://kept.com/", title: "Kept", at: day(3))
            store.visit("https://kept.com/", title: "", at: day(2))
            store.visit("https://later.com/a?b=c", title: "Later\nwith a line", at: day(1))
            store.visit("https://gone.com/", title: "Gone", at: day(1))
            store.delete("https://gone.com/")
            store.retitle("https://kept.com/", title: "Kept again")
        }
        let read = HistoryStore(table: try TestState.table("history", at: path))
        #expect(read.entries().map(\.url) == ["https://later.com/a?b=c", "https://kept.com/"])
        #expect(read.entries().map(\.title) == ["Later\nwith a line", "Kept again"])
        #expect(read.entries().last?.visits == 2 && read.entries().last?.lastVisit == day(2))
        read.expire(before: day(1.5))
        #expect(
            HistoryStore(table: try TestState.table("history", at: path)).entries().map(\.title) == [
                "Later\nwith a line"
            ]
        )
    }

    @Test
    func `search ignores the case of plain letters, in the address and in the title, latest first, up to a limit`() {
        let store = HistoryStore()
        store.visit("https://Example.com/Tides", title: "North Sea", at: day(3))
        store.visit("https://b.org/", title: "The TIDES of March", at: day(2))
        store.visit("https://c.org/", title: "Élan", at: day(1))
        #expect(store.entries(matching: "tides").map(\.url) == ["https://b.org/", "https://Example.com/Tides"])
        #expect(store.entries(matching: "TIDES", limit: 1).map(\.url) == ["https://b.org/"])
        #expect(store.entries(matching: "Élan").count == 1 && store.entries(matching: "nothing").isEmpty)
        #expect(store.entries(matching: "").count == 3)
    }

    @Test func `the history of before the database is read once, with its counts and times`() throws {
        let folder = NSTemporaryDirectory() + "legacy-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let old = folder + "/history.sqlite"
        try TestState.makeLegacyHistory(
            at: old,
            pages: [
                HistoryEntry(url: "https://a.com/", title: "A", visits: 3, lastVisit: Date(timeIntervalSince1970: 100)),
                HistoryEntry(url: "https://b.com/", title: "B", visits: 1, lastVisit: Date(timeIntervalSince1970: 200))
            ]
        )
        let store = HistoryStore(table: try TestState.table("history", at: folder + "/state.sqlite"))
        #expect(store.importLegacy(at: old) == 2)
        #expect(store.entries().map(\.url) == ["https://b.com/", "https://a.com/"] && store.entries().last?.visits == 3)
        #expect(store.importLegacy(at: folder + "/none.sqlite") == nil)
        let read = HistoryStore(table: try TestState.table("history", at: folder + "/state.sqlite"))
        #expect(read.entries().count == 2 && read.entries().first?.lastVisit == Date(timeIntervalSince1970: 200))
    }

    @Test func `a long history is read off the main actor; what is visited or removed meanwhile is joined to it`()
        async throws
    {
        let path = NSTemporaryDirectory() + "history-\(UUID().uuidString)/state.sqlite"
        do {
            let store = HistoryStore(table: try TestState.table("history", at: path))
            for (index, name) in ["old", "seen", "gone", "recent", "kept"].enumerated() {
                store.visit("https://\(name).com/", title: name.capitalized, at: day(Double(10 - index)))
            }
        }
        // Every history is "long" for this store: it reads in the background, as one of thousands would.
        let store = HistoryStore(table: try TestState.table("history", at: path), atOnceBelow: 0)
        var changes = 0
        store.onChange = { changes += 1 }
        #expect(!store.isLoaded && store.entries().isEmpty)
        store.visit("https://seen.com/", title: "", at: day(0.5))
        store.visit("https://new.com/", title: "New", at: day(0.4))
        store.delete("https://gone.com/")
        store.expire(before: day(9.5))
        store.clear(since: day(0.45))
        await store.ready()
        #expect(store.isLoaded && changes > 0)
        #expect(store.entries().map(\.url) == ["https://seen.com/", "https://kept.com/", "https://recent.com/"])
        let seen = try #require(store.entries().first)
        #expect(seen.visits == 2 && seen.title == "Seen" && seen.lastVisit == day(0.5))
        let read = HistoryStore(table: try TestState.table("history", at: path))
        #expect(read.entries().map(\.url) == store.entries().map(\.url) && read.entries().first?.visits == 2)
    }
}

/// The history as a file of the person's (R12 step ST-6).
extension HistoryStoreTests {
    @Test func `the history exports as CSV, the latest first, every page (not the 500 a list shows)`() throws {
        let store = HistoryStore()
        store.visit("https://a.com/?q=1,2", title: "A, \"quoted\"", at: day(2))
        store.visit("https://b.com/", title: "=cmd()", at: day(1))
        store.visit("https://b.com/", title: "=cmd()", at: day(1))
        let lines = store.csv().components(separatedBy: "\r\n")
        #expect(lines[0] == "address,title,last visit,visits")
        #expect(lines[1] == "https://b.com/,'=cmd(),\(day(1).ISO8601Format()),2")
        #expect(lines[2] == "\"https://a.com/?q=1,2\",\"A, \"\"quoted\"\"\",\(day(2).ISO8601Format()),1")
        #expect(lines.count == 4 && lines[3].isEmpty)

        let many = HistoryStore()
        for index in 0 ..< 700 { many.visit("https://x.com/\(index)", title: "", at: day(Double(index))) }
        #expect(many.csv().components(separatedBy: "\r\n").count == 702)
    }
}
