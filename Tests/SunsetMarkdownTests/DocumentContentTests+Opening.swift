import Foundation
import MarkdownLookKit
import SunsetDocuments
import SunsetPane
import Testing

@testable import SunsetMarkdown

/// What a document pane opens, and what it asks of the page.
extension DocumentContentTests {
    @Test func `an empty document opens as source, ready to type; one with text opens rendered`() throws {
        #expect(try content(try file("empty.md", "")).mode == .source)
        #expect(try content(try file("full.md", "# Full\n")).mode == .rendered)
        #expect(try content(try file("asked.md", ""), mode: "rendered").mode == .rendered, "what was saved is kept")
    }

    @Test func `Show Beside opens the other view of the same document`() throws {
        let pane = try content(try file("b.md", "# B\n"))
        var opened: [DocumentOpening] = []
        pane.onOpen = { opened.append($0) }
        pane.showBeside()
        guard case .document(let other) = try #require(opened.first) else {
            Issue.record("a document pane is opened")
            return
        }
        #expect(other.document === pane.document && other.mode == .source && pane.mode == .rendered)
        #expect(pane.document.paneCount == 2)
        let text = try content(try file("b.txt", "text\n"))
        text.onOpen = { opened.append($0) }
        text.showBeside()
        #expect(opened.count == 1, "a text file has one view")
        other.stop()
        pane.stop()
        text.stop()
    }

    @Test func `a link is opened beside: a web address as a page, a file as a document, mail by the system`() throws {
        let pane = try content(try file("links.md", "[a](other.md)\n"))
        _ = try file("other.md", "# Other\n")
        var opened: [DocumentOpening] = []
        pane.onOpen = { opened.append($0) }
        let web = try #require(URL(string: "https://example.org/a"))
        let mail = try #require(URL(string: "mailto:me@example.org"))
        pane.open(link: web)
        pane.open(link: URL(fileURLWithPath: root + "/other.md"))
        pane.open(link: mail)
        pane.open(link: URL(fileURLWithPath: root))
        #expect(opened.count == 4)
        if case .web(let url) = opened[0] { #expect(url == web) } else { Issue.record("a page") }
        if case .document(let other) = opened[1] {
            #expect(other.title == "other.md" && other.document !== pane.document)
            other.stop()
        } else {
            Issue.record("a document")
        }
        if case .system(let url) = opened[2] { #expect(url == mail) } else { Issue.record("the system") }
        if case .system = opened[3] {} else { Issue.record("a folder is the Finder's") }
        #expect(pane.base == URL(fileURLWithPath: root, isDirectory: true))
        pane.stop()
    }

    @Test func `the page is made for a pane that shows it rendered on screen, and let go with the last such pane`()
        throws
    {
        let pane = try content(try file("p.md", "# P\n\ntext\n"))
        let page = pane.document.page
        #expect(page.made == 0, "not shown yet")
        pane.setState(focused: true, visible: true)
        #expect(page.made == 1 && page.shown.rows.count == 2)
        pane.setState(focused: false, visible: false)
        #expect(page.shown.rows.count == 2, "kept for when the tab comes back")
        pane.toggleMode()
        #expect(page.shown.rows.isEmpty, "source only: no page is held")
        pane.toggleMode()
        pane.setState(focused: true, visible: true)
        #expect(page.made == 2)
        pane.stop()
        #expect(page.shown.rows.isEmpty)
    }

    @Test func `a file that changed on disk under edits is reloaded or kept, as the person says`() throws {
        let path = try file("c.md", "disk\n")
        let pane = try content(path)
        type("mine\n", into: pane)
        try "theirs\n".write(toFile: path, atomically: true, encoding: .utf8)
        pane.document.checkFile()
        #expect(pane.document.changedOnDisk && pane.document.source.text == "disk\nmine\n")
        pane.document.keepEdits()
        #expect(!pane.document.changedOnDisk && pane.isEdited)
        try "theirs again\n".write(toFile: path, atomically: true, encoding: .utf8)
        pane.document.checkFile()
        #expect(pane.document.changedOnDisk)
        pane.document.reloadFromDisk()
        #expect(!pane.document.changedOnDisk && !pane.isEdited && pane.document.source.text == "theirs again\n")
        pane.stop()
    }

    @Test func `bigger and smaller text, in both views, within bounds`() throws {
        let pane = try content(try file("z.md", "text\n"))
        pane.zoom(by: 1)
        #expect(pane.document.source.settings.textSize == 14 && pane.fontSize == 14)
        for _ in 0 ..< 30 { pane.zoom(by: 1) }
        #expect(pane.document.source.settings.textSize == 20 && pane.fontSize == 20)
        pane.resetZoom()
        #expect(pane.document.source.settings.textSize == 13 && pane.fontSize == 13)
        pane.stop()
    }
}
