import Foundation
import SunsetShell
import Testing

@testable import SunsetMarkdown

/// A document's tab menu offers to show the page beside the source, or the source beside the page.
extension DocumentContentTests {
    @Test func `a document's tab menu shows the other view in place or beside; plain text has none`() throws {
        let rendered = try content(try file("menu.md", "# Menu\n"))
        #expect(rendered.menuActions.map(\.title) == ["Show Source", "Show Source Beside"])
        let source = try content(try file("menu2.md", "# Menu\n"), mode: "source")
        #expect(source.menuActions.map(\.title) == ["Show Rendered", "Show Rendering Beside"])
        let text = try content(try file("plain.txt", "plain\n"))
        #expect(text.menuActions.isEmpty)
        rendered.menuActions.first?.run()
        #expect(rendered.mode == .source)
    }
}
