import AppKit
import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// "Have a way to cache favicons when tabs are unloaded". His answers: on disk, across quits; the cache's expiry
/// respected and the icon fetched again then; an icon the page changes while it runs replaces the one kept.
@MainActor
@Suite("Site icons kept")
struct FaviconStoreTests {
    static func pngData(_ colour: NSColor) -> Data {
        png(colour)
    }

    private static func png(_ colour: NSColor, side: Int = 16) -> Data {
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            colour.setFill()
            rect.fill()
            return true
        }
        let tiff = image.tiffRepresentation ?? Data()
        return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) ?? Data()
    }

    private static func response(_ headers: [String: String]) -> HTTPURLResponse? {
        HTTPURLResponse(
            url: URL(string: "https://a.example/favicon.ico")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: headers
        )
    }

    @Test
    func
        `how long an icon is kept: the server's max-age, else its Expires, else a week; no-store and no-cache, not at all`()
    {
        let now = Date(timeIntervalSince1970: 1_000_000)
        #expect(
            FaviconStore.expiry(of: Self.response(["Cache-Control": "public, max-age=3600"]), at: now) == now + 3600
        )
        let expires = "Thu, 01 Jan 1970 12:00:00 GMT"
        #expect(
            FaviconStore.expiry(of: Self.response(["Expires": expires]), at: Date(timeIntervalSince1970: 0))
                == Date(timeIntervalSince1970: 12 * 3600)
        )
        #expect(FaviconStore.expiry(of: Self.response([:]), at: now) == now + FaviconStore.defaultLife)
        #expect(FaviconStore.expiry(of: Self.response(["Cache-Control": "no-cache"]), at: now) == now)
        #expect(FaviconStore.expiry(of: Self.response(["Cache-Control": "no-store"]), at: now) == now)
        #expect(
            FaviconStore.expiry(of: Self.response(["Cache-Control": "max-age=99999999"]), at: now) == now
                + FaviconStore.longestLife
        )
    }

    @Test func `an icon kept is there after a quit, and is fresh until it expires or the page names another`() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("favicons-\(UUID().uuidString).sqlite")
            .path
        defer { try? FileManager.default.removeItem(atPath: path) }
        let now = Date(timeIntervalSince1970: 1_000_000)
        let source = try #require(URL(string: "https://a.example/icon.png"))
        let first = FaviconStore()
        first.table = try TestState.table("favicons", at: path)
        first.keep(host: "a.example", source: source, data: Self.png(.red), expires: now + 60)
        #expect(first.image(for: "a.example") != nil)

        let again = FaviconStore()
        again.table = try TestState.table("favicons", at: path)
        #expect(again.image(for: "a.example") != nil, "read back from the file")
        #expect(again.image(for: "A.EXAMPLE") != nil, "a host is a host whatever its case")
        #expect(again.isFresh(host: "a.example", source: source, at: now + 59))
        #expect(!again.isFresh(host: "a.example", source: source, at: now + 61), "expired")
        #expect(
            !again.isFresh(host: "a.example", source: URL(string: "https://a.example/new.png"), at: now),
            "another icon"
        )
        #expect(again.image(for: "a.example") != nil, "an expired icon is still shown until the new one comes")
    }

    @Test func `an icon is kept small, whatever the server sent`() throws {
        let store = FaviconStore()
        store.keep(host: "big.example", source: nil, data: Self.png(.blue, side: 512), expires: .distantFuture)
        let image = try #require(store.image(for: "big.example"))
        let pixels = try #require(image.representations.first).pixelsWide
        #expect(pixels <= FaviconStore.side)
        #expect(
            store.keep(host: "bad.example", source: nil, data: Data("not an image".utf8), expires: .distantFuture)
                == false
        )
        #expect(store.image(for: "bad.example") == nil)
    }

    @Test func `forgetting all, as clearing the history does, empties the file too`() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("favicons-\(UUID().uuidString).sqlite")
            .path
        defer { try? FileManager.default.removeItem(atPath: path) }
        let store = FaviconStore()
        store.table = try TestState.table("favicons", at: path)
        store.keep(host: "a.example", source: nil, data: Self.png(.red), expires: .distantFuture)
        store.forgetAll()
        #expect(store.image(for: "a.example") == nil)
        let again = FaviconStore()
        again.table = try TestState.table("favicons", at: path)
        #expect(again.image(for: "a.example") == nil)
    }
}
