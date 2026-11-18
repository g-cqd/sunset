import AppKit
import Foundation
import SunsetShell
import Testing

@testable import SunsetWeb

/// Roadmap 0047 F (the owner, 2026-11-18): the address bar offers Copy on hover, and its menu the page's actions.
@MainActor @Suite("What the address bar does with the page's address", .serialized)
struct AddressActionsTests {
    @Test func `Copy puts the page's whole address on the pasteboard, as a link too`() throws {
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let page = WebContent(
            url: URL(string: "https://example.org/path?q=1#part"),
            settings: WebSettings(applicationName: "x")
        )
        #expect(page.copyAddress(to: board) == .done("Copied the address"))
        #expect(board.string(forType: .string) == "https://example.org/path?q=1#part")
        #expect(board.string(forType: .URL) == "https://example.org/path?q=1#part")
        let empty = WebContent(url: nil, settings: WebSettings(applicationName: "x"))
        #expect(empty.copyAddress(to: board) == .blocked("This page has no address"))
    }
}
