import Foundation
import MarkdownLookKit
import SunsetDocuments
import SunsetPane
import SunsetShell
import Testing

@testable import SunsetMarkdown

/// The owner, 2026-11-17 (note n3): "icon for a markdown rendering tab might need to be different than a simple document
/// icon". Rendered, a page with its rich text; as source, the document of text, as before.
@MainActor
@Suite("A document tab's picture")
struct DocumentGlyphTests {
    @Test func `rendered Markdown is a rich-text page; its source, a text document`() throws {
        let root = NSTemporaryDirectory() + "glyph-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: root) }
        try "# Notes\n".write(toFile: root + "/n.md", atomically: true, encoding: .utf8)
        let documents = OpenDocuments(store: nil)
        let pane = try #require(
            DocumentContent(
                PaneDescriptor(kind: DocumentContent.kind, state: ["file": root + "/n.md", "view": "rendered"]),
                documents: documents
            )
        )
        #expect(pane.glyph == .symbol("richtext.page"))
        pane.toggleMode()
        #expect(pane.glyph == .symbol(PaneDescriptor.documentSymbol))
        pane.stop()
    }
}
