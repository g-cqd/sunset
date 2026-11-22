import AppKit
import MarkdownLookKit
import SunsetDocuments
import SunsetShell
import Testing

@testable import SunsetMarkdown

/// The blocks changed here and on disk, as a pane shows them: on the block, in the document; saving shows the first of
/// them and writes nothing.
extension DocumentContentTests {
    private static let text = "# Title\n\nFirst.\n\nSecond.\n\nThird.\n"

    /// A pane on a file with two blocks changed both here and on disk.
    private func conflicted(_ name: String) throws -> (pane: DocumentContent, path: String) {
        let path = try file(name, Self.text)
        let pane = try content(path)
        let storage = pane.document.source.storage
        storage.replaceCharacters(in: (storage.string as NSString).range(of: "First."), with: "First, mine.")
        storage.replaceCharacters(in: (storage.string as NSString).range(of: "Third."), with: "Third, mine.")
        let disk = Self.text.replacing("First.", with: "First, theirs.").replacing("Third.", with: "Third, theirs.")
        try disk.write(toFile: path, atomically: true, encoding: .utf8)
        pane.document.checkFile()
        return (pane, path)
    }

    @Test func `saving with a conflict writes nothing and shows the first one`() throws {
        let (pane, path) = try conflicted("k.md")
        #expect(pane.document.conflicts.count == 2 && pane.conflictPlace == 0)
        let shown = pane.reveal
        pane.save()
        #expect(try String(contentsOfFile: path, encoding: .utf8).contains("First, theirs."))
        #expect(pane.failure == nil, "the bar and the block say it: no line about a failure")
        #expect(pane.reveal == shown + 1 && pane.shownConflict == pane.document.conflicts[0].id)
        #expect(pane.unsaved?.save() == false, "asked to save when closing: nothing closes")
        pane.stop()
    }

    @Test func `next and previous go round them; answering one shows the one that follows; then it saves`() throws {
        let (pane, path) = try conflicted("n.md")
        let ids = pane.document.conflicts.map(\.id)
        pane.showConflict(step: 1)
        #expect(pane.shownConflict == ids[1] && pane.conflictPlace == 1)
        pane.showConflict(step: 1)
        #expect(pane.shownConflict == ids[0])
        pane.showConflict(step: -1)
        #expect(pane.shownConflict == ids[1])
        pane.answer(ids[0], keeping: .theirs)
        #expect(
            pane.document.conflicts.map(\.id) == [ids[1]] && pane.shownConflict == ids[1] && pane.conflictPlace == 0
        )
        pane.answer(ids[1], keeping: .both)
        #expect(pane.document.conflicts.isEmpty && pane.shownConflict == nil && pane.conflictPlace == nil)
        pane.save()
        #expect(pane.failure == nil && !pane.isEdited)
        #expect(
            try String(contentsOfFile: path, encoding: .utf8)
                == "# Title\n\nFirst, theirs.\n\nSecond.\n\nThird, mine.\n\nThird, theirs.\n"
        )
        pane.stop()
    }

    @Test func `the page in parts: the text between the conflicts, and each conflict with what is here`() throws {
        let (pane, _) = try conflicted("s.md")
        let parts = PageParts.of(pane.document.source.text, conflicts: pane.document.conflicts)
        #expect(parts.map(\.text) == ["# Title\n\n", "First, mine.\n\n", "Second.\n\n", "Third, mine.\n"])
        #expect(parts.map { $0.conflict?.theirs } == [nil, "First, theirs.\n\n", nil, "Third, theirs.\n"])
        #expect(parts.map(\.text).joined() == pane.document.source.text)
        #expect(Set(parts.map(\.id)).count == parts.count)
        // A block removed here is a part with nothing in it; nothing before the first conflict is no part.
        let removed = DocumentConflict(id: 9, range: 0 ..< 0, theirs: "x\n", base: "y\n")
        #expect(PageParts.of("abc", conflicts: [removed]).map(\.text) == ["", "abc"])
        #expect(PageParts.of("abc", conflicts: []).map(\.text) == ["abc"])
        pane.stop()
    }

    /// In the source the block written here is tinted where it is, and the disk's is shown under it, in the text view
    /// itself: the text makes room for it.
    @Test func `in the source each conflict has its card under its block, and the text below moves down for it`() throws
    {
        let (pane, _) = try conflicted("v.md")
        let source = pane.document.source
        let view = MarkdownSourceEditor.makeTextView(for: source, configuration: MarkdownEditorConfiguration())
        view.frame = NSRect(x: 0, y: 0, width: 480, height: 600)
        let layout = try #require(unsafe view.layoutManager)
        func top(of text: String) -> CGFloat {
            let glyph = layout.glyphIndexForCharacter(at: (source.text as NSString).range(of: text).location)
            return layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil).minY
        }
        let before = (second: top(of: "Second."), first: top(of: "First, mine."))
        let marks = SourceMarks(content: pane)
        marks.attach(to: view)
        marks.update()
        #expect(marks.cards.count == 2 && marks.cards.allSatisfy { $0.superview === view })
        #expect(top(of: "First, mine.") == before.first, "what is above a card does not move")
        let moved = top(of: "Second.") - before.second
        #expect(moved >= marks.cards[0].frame.height && marks.cards[0].frame.height > 20)
        #expect(
            marks.cards[0].frame.minY >= top(of: "First, mine.") && marks.cards[0].frame.maxY <= top(of: "Second.") + 16
        )
        // In a scroll view the cards are beside the text view, in what scrolls it: accessibility finds them there.
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 480, height: 300))
        scroll.documentView = view
        marks.attach(to: nil)
        marks.attach(to: view)
        marks.update()
        #expect(marks.cards.count == 2 && marks.cards.allSatisfy { $0.superview === scroll.contentView })
        let tint = layout.temporaryAttribute(
            .backgroundColor,
            atCharacterIndex: (source.text as NSString).range(of: "First, mine.").location,
            effectiveRange: nil
        )
        #expect(tint != nil)
        // Answered: its card goes, and the text comes back up.
        pane.answer(pane.document.conflicts[0].id, keeping: .mine)
        marks.update()
        #expect(marks.cards.count == 1 && top(of: "Second.") == before.second)
        pane.answer(pane.document.conflicts[0].id, keeping: .mine)
        marks.update()
        #expect(marks.cards.isEmpty && view.textContainer?.exclusionPaths.isEmpty == true)
        MarkdownSourceEditor.detach(view, from: source)
        pane.stop()
    }
}
