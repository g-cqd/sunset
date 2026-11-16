import Foundation
import MarkdownLookKit
import Testing

@testable import SunsetDocuments

/// A file that changes on disk under edits made here (R6, roadmap 0023 step M-e; the owner's answers of 2026-11-16): the
/// blocks only the disk changed are put in, as one step of undo; a block both changed is a conflict, kept as it is here
/// with the disk's beside it until it is answered; and the file is not written while one is not.
@MainActor
@Suite("A change on disk is merged into the edits made here")
struct OpenDocumentMergingTests {
    private let root: String = {
        let made = NSTemporaryDirectory() + "merging-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: made, withIntermediateDirectories: true)
        return made
    }()
    private let base = "# Title\n\nFirst paragraph.\n\nSecond paragraph.\n\nThird paragraph.\n"

    private func write(_ text: String, to path: String) throws {
        try text.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func read(_ path: String) -> String { (try? String(contentsOfFile: path, encoding: .utf8)) ?? "<none>" }

    private func opened(_ name: String = "a.md") throws -> (document: OpenDocument, path: String) {
        let path = root + "/" + name
        try write(base, to: path)
        return (OpenDocuments(store: nil).open(.file(path)), path)
    }

    private func replace(_ old: String, with new: String, in document: OpenDocument) {
        let range = (document.source.text as NSString).range(of: old)
        document.source.storage.replaceCharacters(in: range, with: new)
    }

    /// The same, as a step of undo (what is typed in an editor is one; a storage changed directly is not).
    private func edit(_ old: String, with new: String, in document: OpenDocument) {
        let range = (document.source.text as NSString).range(of: old)
        let low = range.location
        document.source.apply(MarkdownEdit(range: low ..< low + range.length, replacement: new, selection: low ..< low))
    }

    private func text(of conflict: DocumentConflict, in document: OpenDocument) -> String {
        let range = NSRange(location: conflict.range.lowerBound, length: conflict.range.count)
        return (document.source.text as NSString).substring(with: range)
    }

    @Test func `blocks only the disk changed are put in; mine stay; one undo takes the merge back`() throws {
        let (document, path) = try opened()
        replace("First paragraph.", with: "First, edited here.", in: document)
        try write(base.replacing("Third paragraph.", with: "Third, changed on disk."), to: path)
        document.checkFile()
        let merged = "# Title\n\nFirst, edited here.\n\nSecond paragraph.\n\nThird, changed on disk.\n"
        #expect(document.source.text == merged)
        #expect(document.isEdited && document.conflicts.isEmpty && !document.changedOnDisk)
        let start = "# Title\n\nFirst, edited here.\n\nSecond paragraph.\n\n".utf16.count
        #expect(document.lastMerge?.ranges == [start ..< start + "Third, changed on disk.\n".utf16.count])
        document.source.undoManager.undo()
        #expect(document.source.text == base.replacing("First paragraph.", with: "First, edited here."))
        document.source.undoManager.redo()
        try document.save()
        #expect(read(path) == merged && !document.isEdited)
    }

    @Test func `a block both changed is a conflict: mine is in the text, the disk's beside it, and saving is refused`()
        throws
    {
        let (document, path) = try opened()
        replace("Second paragraph.", with: "Second, mine.", in: document)
        let disk = base.replacing("Second paragraph.", with: "Second, theirs.").replacing("# Title", with: "# Renamed")
        try write(disk, to: path)
        document.checkFile()
        #expect(document.source.text == "# Renamed\n\nFirst paragraph.\n\nSecond, mine.\n\nThird paragraph.\n")
        #expect(document.conflicts.count == 1)
        let conflict = try #require(document.conflicts.first)
        #expect(text(of: conflict, in: document) == "Second, mine.\n\n")
        #expect(conflict.theirs == "Second, theirs.\n\n" && conflict.base == "Second paragraph.\n\n")
        #expect(throws: OpenDocumentFailure.conflicts(1)) { try document.save() }
        #expect(read(path) == disk && document.isEdited)
        #expect(!document.canSaveItself)
    }

    @Test func `a conflict follows the text as it is edited around it and in it`() throws {
        let (document, path) = try opened()
        replace("Second paragraph.", with: "Second, mine.", in: document)
        try write(base.replacing("Second paragraph.", with: "Second, theirs."), to: path)
        document.checkFile()
        edit("# Title", with: "# A much longer title", in: document)
        #expect(text(of: try #require(document.conflicts.first), in: document) == "Second, mine.\n\n")
        edit("Third paragraph.", with: "3.", in: document)
        #expect(text(of: try #require(document.conflicts.first), in: document) == "Second, mine.\n\n")
        edit("Second, mine.", with: "Second, mine, edited again.", in: document)
        #expect(text(of: try #require(document.conflicts.first), in: document) == "Second, mine, edited again.\n\n")
        // The three are undone together here (no turn of the run loop came between them): the range follows that too.
        document.source.undoManager.undo()
        #expect(document.source.text == base.replacing("Second paragraph.", with: "Second, mine."))
        #expect(text(of: try #require(document.conflicts.first), in: document) == "Second, mine.\n\n")
    }

    @Test func `answered with mine, the disk's, or both; then it saves`() throws {
        for (answer, expected) in [
            (DocumentConflict.Answer.mine, "Second, mine.\n\n"), (.theirs, "Second, theirs.\n\n"),
            (.both, "Second, mine.\n\nSecond, theirs.\n\n")
        ] {
            let (document, path) = try opened("\(expected.count).md")
            replace("Second paragraph.", with: "Second, mine.", in: document)
            try write(base.replacing("Second paragraph.", with: "Second, theirs."), to: path)
            document.checkFile()
            document.resolve(try #require(document.conflicts.first).id, keeping: answer)
            let whole = "# Title\n\nFirst paragraph.\n\n" + expected + "Third paragraph.\n"
            #expect(document.conflicts.isEmpty && document.source.text == whole)
            try document.save()
            #expect(read(path) == whole && !document.isEdited)
        }
    }

    @Test func `answered with the disk's everywhere, the text is the file's and is not edited`() throws {
        let (document, path) = try opened()
        replace("Second paragraph.", with: "Second, mine.", in: document)
        let disk = base.replacing("Second paragraph.", with: "Second, theirs.")
        try write(disk, to: path)
        document.checkFile()
        #expect(document.isEdited)
        document.resolve(try #require(document.conflicts.first).id, keeping: .theirs)
        #expect(document.source.text == disk && !document.isEdited)
        // And taking the answer back is an edit again.
        document.source.undoManager.undo()
        #expect(document.isEdited)
    }

    /// The trap of a merge: the text can be undone back to what the file held before, which the file no longer holds.
    @Test func `undone back to the text of before the change on disk, it is still edited: the disk says otherwise`()
        throws
    {
        let (document, path) = try opened()
        edit("First paragraph.", with: "First, edited here.", in: document)
        try write(base.replacing("Third paragraph.", with: "Third, changed on disk."), to: path)
        document.checkFile()
        // The edit and the merge are undone together here (no turn of the run loop came between them).
        document.source.undoManager.undo()
        #expect(document.source.text == base)
        #expect(document.isEdited)
        try document.save()
        #expect(read(path) == base && !document.isEdited)
    }

    @Test
    func `a second change on disk while a conflict waits: what is new is merged, the question is kept or renewed`()
        throws
    {
        let (document, path) = try opened()
        replace("Second paragraph.", with: "Second, mine.", in: document)
        let first = base.replacing("Second paragraph.", with: "Second, theirs.")
        try write(first, to: path)
        document.checkFile()
        // The disk changes another block: merged, and the question stands as it was.
        try write(first.replacing("Third paragraph.", with: "Third, later."), to: path)
        document.checkFile()
        #expect(document.source.text == "# Title\n\nFirst paragraph.\n\nSecond, mine.\n\nThird, later.\n")
        #expect(document.conflicts.map(\.theirs) == ["Second, theirs.\n\n"])
        #expect(text(of: try #require(document.conflicts.first), in: document) == "Second, mine.\n\n")
        // The disk changes the block in question again: one question, with what the disk says now.
        try write(first.replacing("Second, theirs.", with: "Second, theirs again."), to: path)
        document.checkFile()
        #expect(
            document.conflicts.map(\.theirs) == ["Second, theirs again.\n\n"],
            "\(document.conflicts) \(document.source.text.debugDescription)"
        )
        #expect(text(of: try #require(document.conflicts.first), in: document) == "Second, mine.\n\n")
    }

    @Test func `the disk comes to say what is here: nothing is merged, and nothing is edited any more`() throws {
        let (document, path) = try opened()
        replace("First paragraph.", with: "First, edited here.", in: document)
        try write(document.source.text, to: path)
        document.checkFile()
        #expect(!document.isEdited && document.conflicts.isEmpty && document.lastMerge == nil)
    }

    @Test func `unedited, the file is taken whole as before; reloading from disk drops the questions`() throws {
        let (document, path) = try opened()
        try write("# Other\n", to: path)
        document.checkFile()
        #expect(document.source.text == "# Other\n" && !document.isEdited && document.lastMerge == nil)
        replace("# Other", with: "# Mine", in: document)
        try write("# Theirs\n", to: path)
        document.checkFile()
        #expect(document.conflicts.count == 1)
        document.reloadFromDisk()
        #expect(document.conflicts.isEmpty && document.source.text == "# Theirs\n" && !document.isEdited)
    }

    @Test func `a file that stops being text under edits is not merged: it is said, as before`() throws {
        let (document, path) = try opened()
        replace("First paragraph.", with: "First, edited here.", in: document)
        try Data([0xFF, 0xFE, 0x00, 0x41]).write(to: URL(fileURLWithPath: path))
        document.checkFile()
        #expect(document.changedOnDisk && document.conflicts.isEmpty)
        #expect(document.source.text == base.replacing("First paragraph.", with: "First, edited here."))
    }

    /// A long text is compared off the main actor: what is typed meanwhile is not lost, and the merge is made of the text
    /// as it then is.
    @Test func `a long text is merged off the main actor, and typing meanwhile makes it start again`() async throws {
        let path = root + "/long.md"
        let long = (0 ..< 9000).map { "Paragraph number \($0) of a long text.\n\n" }.joined()
        try write(long, to: path)
        let document = OpenDocuments(store: nil).open(.file(path))
        #expect(document.source.storage.length > OpenDocument.inlineMergeLimit)
        replace("Paragraph number 3 of", with: "Paragraph three, mine, of", in: document)
        let disk = long.replacing("Paragraph number 8000 of", with: "Paragraph 8000, theirs, of")
        try write(disk, to: path)
        let settling = Task { await document.fileSettled(.read(path)) }
        // Typed while the three texts are being compared.
        await Task.yield()
        replace("Paragraph number 5 of", with: "Paragraph five, typed meanwhile, of", in: document)
        await settling.value
        let text = document.source.text
        #expect(text.contains("Paragraph three, mine, of") && text.contains("Paragraph five, typed meanwhile, of"))
        #expect(text.contains("Paragraph 8000, theirs, of") && document.conflicts.isEmpty && document.isEdited)
        try document.save()
        #expect(read(path) == text)
    }
}
