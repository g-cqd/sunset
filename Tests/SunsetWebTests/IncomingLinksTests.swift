import Foundation
import Testing

@testable import SunsetWeb

/// The owner's note n18 (2026-11-18): "sunset still does not act as a browser for macos and cannot be set as default browser".
/// What the system hands Sunset to open: links to pages, and files.
@Suite("What another app asks Sunset to open")
struct IncomingLinksTests {
    @Test func `web links are pages; files are files; anything else is neither`() throws {
        let urls = try [
            #require(URL(string: "https://example.org/a?b=1")),
            #require(URL(string: "http://example.org/")),
            URL(fileURLWithPath: "/tmp/notes.md"),
            #require(URL(string: "mailto:someone@example.org")),
            #require(URL(string: "javascript:alert(1)"))
        ]
        let split = IncomingLinks.split(urls)
        #expect(split.pages.map(\.absoluteString) == ["https://example.org/a?b=1", "http://example.org/"])
        #expect(split.files == ["/tmp/notes.md"])
    }
}
