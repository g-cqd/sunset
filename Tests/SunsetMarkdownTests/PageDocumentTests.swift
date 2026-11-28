import Foundation
import SunsetDocuments
import SunsetPane
import Testing

@testable import SunsetMarkdown

/// An HTML, XHTML or SVG file is a page: it opens drawn (by WebKit, which the app gives), its source a toggle away; any
/// other text stays source only.
@MainActor
@Suite("A page document")
struct PageDocumentTests {
    @Test func `HTML, XHTML and SVG are pages; Markdown and Mermaid are drawn here; the rest is text`() {
        for name in ["index.html", "a.HTM", "b.xhtml", "logo.svg"] {
            #expect(DocumentKind(path: name) == .page, "\(name)")
        }
        #expect(DocumentKind(path: "notes.md") == .markdown && DocumentKind(path: "chart.mmd") == .mermaid)
        #expect(DocumentKind(path: "main.swift") == .text && DocumentKind(path: "README") == .text)
    }

    @Test func `a page opens drawn, by the app's view and not the native page; its source a toggle away`() throws {
        let root = NSTemporaryDirectory() + "page-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: root) }
        let path = root + "/index.html"
        try "<h1>Hi</h1>".write(toFile: path, atomically: true, encoding: .utf8)
        let documents = OpenDocuments(store: nil)
        let pane = try #require(
            DocumentContent(PaneDescriptor(kind: DocumentContent.kind, state: ["file": path]), documents: documents)
        )
        #expect(pane.mode == .rendered && pane.canRender && !pane.hasNativePage)
        #expect(pane.file?.lastPathComponent == "index.html")
        pane.toggleMode()
        #expect(pane.mode == .source)
        pane.stop()
    }

    @Test func `Sunset opens what it draws and the text people read; the rest goes to the Mac`() {
        for name in ["a.md", "b.mmd", "c.html", "d.svg", "e.swift", "f.json", "g.log", "h.csv"] {
            #expect(DocumentKind.opens(path: "/x/" + name), "\(name)")
        }
        for name in ["a.pdf", "b.zip", "c.app", "README", ".zshrc", "d.docx"] {
            #expect(!DocumentKind.opens(path: "/x/" + name), "\(name)")
        }
    }

    @Test func `with documents.opensAs on source, a file that could be drawn opens as its source`() throws {
        let root = NSTemporaryDirectory() + "page-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: root) }
        let path = root + "/notes.md"
        try "# Notes".write(toFile: path, atomically: true, encoding: .utf8)
        let documents = OpenDocuments(store: nil)
        documents.look.opensSource = true
        let pane = try #require(
            DocumentContent(PaneDescriptor(kind: DocumentContent.kind, state: ["file": path]), documents: documents)
        )
        #expect(pane.mode == .source)
        pane.stop()
        let asked = try #require(
            DocumentContent(
                PaneDescriptor(kind: DocumentContent.kind, state: ["file": path, "view": "rendered"]),
                documents: documents
            )
        )
        #expect(asked.mode == .rendered, "a tab that comes back keeps its view")
        asked.stop()
    }
}
