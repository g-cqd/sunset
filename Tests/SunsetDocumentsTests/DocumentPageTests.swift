import Foundation
import MarkdownLookKit
import Testing

@testable import SunsetDocuments

/// The rendered page of a document (roadmap 0023 step M-c): one for every pane that shows it, made only while one does, at
/// once for a short text and off the main actor for a long one, where keys typed meanwhile make one more page and not one each.
@MainActor
@Suite("The page of a document, made for the panes that show it")
struct DocumentPageTests {
    private final class Pane {}

    private func type(_ text: String, into source: MarkdownSource) {
        source.storage.replaceCharacters(in: NSRange(location: source.storage.length, length: 0), with: text)
    }

    @Test func `no pane shows the page: none is made`() async {
        let source = MarkdownSource(text: "# One\n\ntext\n")
        let page = DocumentPage(source: source)
        type("more\n", into: source)
        await page.settled()
        #expect(page.made == 0 && page.shown.rows.isEmpty)
    }

    @Test func `a short text's page is there when a pane shows it, and follows the text and the settings`() async {
        let source = MarkdownSource(text: "# One\n\ntext\n")
        let page = DocumentPage(source: source)
        let pane = Pane()
        page.setInterest(true, of: pane)
        #expect(page.made == 1 && page.shown.rows.count == 2, "made at once: no empty frame")
        type("\n## Two\n", into: source)
        await page.settled()
        #expect(page.made == 2 && page.shown.rows.count == 3)
        source.settings.showsLanguage.toggle()
        await page.settled()
        #expect(page.made == 3)
        page.setInterest(true, of: pane)
        #expect(page.made == 3, "nothing changed: nothing is made")
    }

    @Test
    func
        `a long text's page is made off the main actor, and what is typed meanwhile makes one more page, not one each`()
        async
    {
        let gate = PageGate()
        let source = MarkdownSource(text: "# One\n\ntext\n")
        let page = DocumentPage(source: source, inlineLimit: 0) { snapshot in
            await gate.pass()
            return DocumentPage.make(snapshot)
        }
        let pane = Pane()
        page.setInterest(true, of: pane)
        #expect(page.made == 0 && page.shown.rows.isEmpty, "the main actor did not wait for it")
        await gate.arrived()
        for index in 0 ..< 10 { type("\n## Part \(index)\n", into: source) }
        await gate.release()
        await page.settled()
        #expect(page.made == 2, "the page of when it was asked for, then one with all that was typed since")
        #expect(page.shown.rows.count == 12)
    }

    @Test func `a page no pane has on screen is kept as it was, and made again when one comes back`() async {
        let source = MarkdownSource(text: "# One\n")
        let page = DocumentPage(source: source)
        let pane = Pane()
        page.setInterest(true, of: pane)
        page.setInterest(false, of: pane)
        type("\ntext\n", into: source)
        await page.settled()
        #expect(page.made == 1 && page.shown.rows.count == 1, "the tab is not shown: nothing is made for it")
        page.setInterest(true, of: pane)
        #expect(page.made == 2 && page.shown.rows.count == 2)
    }

    @Test func `when the last pane that shows it is gone the page is let go; plain text has none`() async {
        let source = MarkdownSource(text: "# One\n")
        let page = DocumentPage(source: source)
        let first = Pane()
        let second = Pane()
        page.setInterest(true, of: first)
        page.setInterest(false, of: second)
        page.setInterest(nil, of: first)
        #expect(page.shown.rows.count == 1, "another pane still shows it rendered, in a tab that is not selected")
        page.setInterest(nil, of: second)
        #expect(page.shown.rows.isEmpty)
        let plain = DocumentPage(source: MarkdownSource(text: "# not Markdown\n", content: .plain))
        plain.setInterest(true, of: first)
        await plain.settled()
        #expect(plain.made == 0 && plain.shown.rows.isEmpty)
        let diagram = DocumentPage(source: MarkdownSource(text: "flowchart LR\n  A --> B\n", content: .diagram))
        diagram.setInterest(true, of: first)
        #expect(diagram.shown.rows.count == 1)
    }
}
