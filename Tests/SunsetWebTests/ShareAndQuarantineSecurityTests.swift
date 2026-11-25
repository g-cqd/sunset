import Foundation
import SunsetWebModel
import Testing

@testable import SunsetWeb

/// Security regressions for HIGH-05 (`ShareSession` origin isolation) and MED-04 (`Quarantine` extended attribute).
@Suite("Share session origin isolation and download quarantine")
struct ShareAndQuarantineSecurityTests {
    @Test @MainActor func `cross-origin pull and end cannot hijack another origin's share session`() async {
        let feed = ShareFeed(
            frame: { nil },
            isOpen: { true },
            host: { "docs.example" },
            shared: { _ in },
            page: { nil }
        )
        let page = WebContent(url: nil, settings: WebSettings())
        let session = ShareSession(source: UUID(), feed: feed, page: page, asker: "https://meet.example:443")
        session.deliver("ZmFrZS1qcGVn")

        // A different origin (or nil origin) must never pull frames or terminate the session.
        #expect(await session.pull(from: "https://evil.example:443") == nil)
        #expect(await session.pull(from: "http://meet.example:80") == nil)
        #expect(await session.pull(from: nil) == nil)
        session.ended(by: "https://evil.example:443")
        session.ended(by: nil)
        #expect(session.stopped == nil)

        // The authorised origin receives the frame and can end its own session.
        #expect(await session.pull(from: "https://meet.example:443") == "ZmFrZS1qcGVn")
        session.ended(by: "https://meet.example:443")
        #expect(session.stopped == TabShare.Stop.stopped)
    }

    @Test func `quarantine marks a downloaded file with com.apple.quarantine xattr`() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "sunset-quarantine-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let file = dir.appending(path: ".sunset-tmp-file")
        try Data("payload".utf8).write(to: file)
        let source = try #require(URL(string: "https://downloads.example/archive.zip"))
        let origin = try #require(URL(string: "https://downloads.example/"))
        Quarantine.mark(file, source: source, origin: origin)

        let size = getxattr(file.path, "com.apple.quarantine", nil, 0, 0, 0)
        #expect(size > 0)
        var buffer = [UInt8](repeating: 0, count: size)
        let read = getxattr(file.path, "com.apple.quarantine", &buffer, size, 0, 0)
        #expect(read == size)
        let value = String(decoding: buffer, as: UTF8.self)
        #expect(value.contains("Sunset"))
    }
}
