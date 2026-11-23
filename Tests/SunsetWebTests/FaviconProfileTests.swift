import AppKit
import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Two Spaces of two profiles with the same site pinned shared one icon, though a site can say something of the page
/// shown through its icon (an unread count).
@MainActor @Suite("Site icons kept per profile")
struct FaviconProfileTests {
    @Test func `a profile's icon of a site is its own; the first profile reads what was kept before profiles`() {
        let store = FaviconStore()
        let work = UUID()
        let red = FaviconStoreTests.pngData(.red)
        let blue = FaviconStoreTests.pngData(.blue)
        store.keep(host: "chat.example", profile: nil, source: nil, data: red, expires: .distantFuture)
        store.keep(host: "chat.example", profile: work, source: nil, data: blue, expires: .distantFuture)
        let first = store.image(for: "chat.example", profile: nil)
        let other = store.image(for: "chat.example", profile: work)
        #expect(first != nil && other != nil && first !== other)
        #expect(store.image(for: "chat.example", profile: UUID()) == nil, "a third profile has none yet")
        #expect(store.isFresh(host: "chat.example", profile: work, source: nil))
        #expect(!store.isFresh(host: "chat.example", profile: UUID(), source: nil))
    }

    /// History shows a page's kept icon (the owner's note n120): looked up by its address, the window's profile first.
    @Test func `a page's icon by its address: the profile's, else the first profile's, else none`() {
        let store = FaviconStore()
        let work = UUID()
        store.keep(
            host: "news.example",
            profile: nil,
            source: nil,
            data: FaviconStoreTests.pngData(.red),
            expires: .distantFuture
        )
        store.keep(
            host: "chat.example",
            profile: work,
            source: nil,
            data: FaviconStoreTests.pngData(.blue),
            expires: .distantFuture
        )
        #expect(store.image(forPage: "https://chat.example/room/1", profile: work) != nil)
        #expect(store.image(forPage: "https://News.Example/a?b", profile: work) != nil, "the first profile's")
        #expect(store.image(forPage: "https://chat.example/", profile: nil) == nil, "not another profile's")
        #expect(store.image(forPage: "about:blank", profile: nil) == nil)
        #expect(store.image(forPage: "https://none.example/", profile: work) == nil)
    }
}
