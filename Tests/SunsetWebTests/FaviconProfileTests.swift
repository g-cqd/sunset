import AppKit
import Foundation
import Testing

@testable import SunsetWeb

/// The owner's note n17 (2026-11-18): two Spaces of two profiles with the same site pinned shared one icon, though a site can
/// say something of the page shown through its icon (an unread count).
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
}
