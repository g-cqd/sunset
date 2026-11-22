import AppKit
import Foundation
import SunsetDocuments
import SunsetPane
import Testing

@testable import SunsetMarkdown

/// A link of a rendered document has a menu, as a page's link has: open it in a new tab, a tab behind, beside, in a new
/// window; copy it.
extension DocumentContentTests {
    @Test func `a link's menu opens it where it says, whatever the keys and the setting; Copy Link copies it`() throws {
        let pane = try content(try file("menu.md", "[a](https://example.org/a)\n"))
        var places: [LinkPlace] = []
        pane.onOpen = { _, place in places.append(place) }
        let web = try #require(URL(string: "https://example.org/a"))
        pane.documents.look.linksBeside = true
        let items = DocumentLinkMenu.items(for: web)
        #expect(
            items.map(\.title) == ["Open in New Tab", "Open in Background Tab", "Open Beside", "Open in New Window"]
        )
        for item in items { pane.open(link: web, in: item.place) }
        #expect(places == [.tab, .backgroundTab, .beside, .window])
        let board = NSPasteboard.withUniqueName()
        DocumentLinkMenu.copy(web, to: board)
        #expect(board.string(forType: .string) == "https://example.org/a")
        let file = URL(fileURLWithPath: "/tmp/a b.md")
        DocumentLinkMenu.copy(file, to: board)
        #expect(board.string(forType: .string) == "/tmp/a b.md", "a file is copied as its path")
        pane.stop()
    }
}
