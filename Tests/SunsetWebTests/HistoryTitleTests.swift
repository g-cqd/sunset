import Foundation
import Testing

@testable import SunsetWebModel

/// A page never loaded in this run is listed by its host where it has no title of its own; the history knows what it
/// was called.
@MainActor @Suite("A page's title from the history")
struct HistoryTitleTests {
    @Test func `the last title an address was seen with; nil for one never seen or seen without a title`() {
        let store = HistoryStore(table: nil)
        store.visit("https://example.org/a", title: "The A page")
        store.visit("https://example.org/b", title: "")
        #expect(store.title(of: "https://example.org/a") == "The A page")
        #expect(store.title(of: "https://example.org/b") == nil)
        #expect(store.title(of: "https://example.org/never") == nil)
    }
}
