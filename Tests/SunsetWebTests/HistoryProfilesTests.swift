import Foundation
import Testing

@testable import SunsetWebModel

/// A page's history notes the profiles it was visited in: kept and read back; a page kept before is every profile's.
@MainActor @Suite("The profiles a page was visited in")
struct HistoryProfilesTests {
    @Test func `each profile a page is visited in is noted once, kept, and read back with its title`() throws {
        let folder = NSTemporaryDirectory() + "history-profiles-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let store = HistoryStore(table: try TestState.table("history", at: folder + "/state.sqlite"))
        store.visit("https://example.org/", title: "Example", profile: "work")
        store.visit("https://example.org/", title: "", profile: "home")
        store.visit("https://example.org/", title: "", profile: "work")
        store.visit("https://old.example/", title: "Old")
        let read = HistoryStore(table: try TestState.table("history", at: folder + "/state.sqlite"))
        let page = try #require(read.entries().first { $0.url == "https://example.org/" })
        #expect(page.profiles == ["work", "home"] && page.title == "Example" && page.visits == 3)
        #expect(page.isVisited(in: "home") && !page.isVisited(in: "other"))
        let old = try #require(read.entries().first { $0.url == "https://old.example/" })
        #expect(old.profiles.isEmpty && old.isVisited(in: "other"))
        #expect(read.entries(matching: "work").isEmpty, "the profiles are not searched as the page's text")
    }
}
