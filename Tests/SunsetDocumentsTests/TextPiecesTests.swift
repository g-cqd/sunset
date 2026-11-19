import Testing

@testable import SunsetDocuments

/// A text cut into the pieces a merge works on (R6, roadmap 0023 step M-e): the top-level blocks of Markdown, each with the
/// blank lines after it; the lines of anything else. Whatever the text, the pieces joined are the text, byte for byte:
/// a merge that puts pieces together can then never lose or invent a character between them.
@Suite("A text in pieces")
struct TextPiecesTests {
    private func joined(_ pieces: [TextPiece]) -> String {
        pieces.map { String($0.text) }.joined()
    }

    @Test func `Markdown is cut at its top-level blocks, the blank lines after a block with it`() {
        let text = "# Title\n\nOne paragraph\nof two lines.\n\n\n- a\n- b\n\n```\ncode\n\nmore\n```\n\nEnd"
        let pieces = TextPieces.of(text, kind: .markdown).map { String($0.text) }
        #expect(
            pieces == [
                "# Title\n\n", "One paragraph\nof two lines.\n\n\n", "- a\n- b\n\n", "```\ncode\n\nmore\n```\n\n", "End"
            ]
        )
    }

    @Test func `what comes before the first block is with it; a head is a block; an empty text has no piece`() {
        #expect(TextPieces.of("\n\n# A\n", kind: .markdown).map { String($0.text) } == ["\n\n# A\n"])
        let head = "---\ntitle: x\n---\n\n# A\n"
        #expect(TextPieces.of(head, kind: .markdown).map { String($0.text) } == ["---\ntitle: x\n---\n\n", "# A\n"])
        #expect(TextPieces.of("", kind: .markdown).isEmpty && TextPieces.of("", kind: .text).isEmpty)
        #expect(TextPieces.of("  \n\n", kind: .markdown).map { String($0.text) } == ["  \n\n"])
    }

    @Test func `anything else is cut at its lines, each with its ending`() {
        #expect(TextPieces.of("a\nb\r\n\nc", kind: .text).map { String($0.text) } == ["a\n", "b\r\n", "\n", "c"])
        #expect(
            TextPieces.of("graph TD\n  A-->B\n", kind: .mermaid).map { String($0.text) } == ["graph TD\n", "  A-->B\n"]
        )
    }

    @Test func `pieces are told apart by their bytes, not by what they look like`() {
        let composed = TextPieces.of("caf\u{E9}\n", kind: .text)
        let decomposed = TextPieces.of("cafe\u{301}\n", kind: .text)
        #expect(String(composed[0].text) == String(decomposed[0].text))
        #expect(composed != decomposed)
    }

    @Test(arguments: [DocumentKind.markdown, .text, .mermaid])
    func `the pieces joined are the text, whatever it is`(kind: DocumentKind) {
        var random = MergeRandom(seed: 0x5EED + UInt64(kind.rawValue.count))
        for _ in 0 ..< 300 {
            let text = random.document()
            let pieces = TextPieces.of(text, kind: kind)
            #expect(Array(joined(pieces).utf8) == Array(text.utf8), "\(text.debugDescription)")
            #expect(pieces.allSatisfy { !$0.text.isEmpty })
        }
    }
}
