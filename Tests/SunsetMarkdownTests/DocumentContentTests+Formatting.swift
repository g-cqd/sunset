import Foundation
import MarkdownLookKit
import SunsetDocuments
import Testing

@testable import SunsetMarkdown

/// Tests Markdown formatting commands and table insertion wired into `DocumentContent` (M-g / t210).
extension DocumentContentTests {
    @Test func `formatting applies to markdown only, switches to source, and inserts undoable table`() throws {
        let mdPath = try file("format.md", "Hello world")
        let md = try content(mdPath, mode: "rendered")
        #expect(md.canFormatMarkdown)
        #expect(md.mode == .rendered)

        md.insertMarkdownTable()
        #expect(md.mode == .source)
        #expect(md.document.source.text.contains("| Column 1 | Column 2 |"))
        #expect(md.isEdited)
        md.document.source.undoManager.undo()
        #expect(md.document.source.text == "Hello world")
        md.stop()

        let txtPath = try file("plain.txt", "plain")
        let txt = try content(txtPath)
        #expect(!txt.canFormatMarkdown)
        txt.stop()
    }
}
