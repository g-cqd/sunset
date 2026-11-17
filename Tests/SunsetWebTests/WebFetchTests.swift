import AppKit
import Foundation
import Testing

@testable import SunsetWeb

/// What Sunset fetches for a page (a site's icon, a notification's picture) is a page's input (white paper §9; the review of
/// 2026-11-17): only from the web or a `data:` address, never a file of the Mac, and never more than its limit is read.
@Suite("Fetching for a page")
struct WebFetchTests {
    @Test func `a file of the Mac is never read for a page`() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(
            "sunset-fetch-\(UUID().uuidString).txt"
        )
        try Data("secret".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        #expect(!WebFetch.allows(file))
        #expect(await WebFetch.data(file, agent: "Safari", limit: 1 << 20) == nil)
        #expect(WebFetch.allows(try #require(URL(string: "https://example.com/a.png"))))
        #expect(WebFetch.allows(try #require(URL(string: "data:text/plain,a"))))
    }

    @Test func `no more than the limit is read`() async throws {
        let body = String(repeating: "a", count: 2048)
        let address = try #require(URL(string: "data:text/plain," + body))
        #expect(await WebFetch.data(address, agent: "Safari", limit: 1024) == nil)
        #expect(await WebFetch.data(address, agent: "Safari", limit: 4096)?.data.count == 2048)
    }
}
