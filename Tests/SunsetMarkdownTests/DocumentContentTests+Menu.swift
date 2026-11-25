import Foundation
import SunsetDocuments
import SunsetShell
import Testing

@testable import SunsetMarkdown

/// A document's tab menu offers to show the page beside the source, or the source beside the page, and Reveal in Finder
/// when opened from disk (t365).
extension DocumentContentTests {
    @Test
    func `a document's tab menu shows the other view in place or beside, and Reveal in Finder for external files`()
        throws
    {
        let rendered = try content(try file("menu.md", "# Menu\n"))
        #expect(rendered.menuActions.map(\.title) == ["Show Source", "Show Source Beside", "Reveal in Finder"])
        let source = try content(try file("menu2.md", "# Menu\n"), mode: "source")
        #expect(source.menuActions.map(\.title) == ["Show Rendered", "Show Rendering Beside", "Reveal in Finder"])
        let text = try content(try file("plain.txt", "plain\n"))
        #expect(text.menuActions.map(\.title) == ["Reveal in Finder"])
        rendered.menuActions.first?.run()
        #expect(rendered.mode == .source)

        // Internal stored documents have no external file on disk, so no Reveal in Finder.
        let stored = DocumentContent(
            document: documents.open(.stored(UUID())),
            mode: .rendered,
            documents: documents
        )
        #expect(stored.externalFileURL == nil)
        #expect(stored.menuActions.map(\.title) == ["Show Source", "Show Source Beside"])
    }
}
