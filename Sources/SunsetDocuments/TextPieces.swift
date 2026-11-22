internal import AemiMarkdown
internal import MarkdownLookKit

/// A text cut into the pieces a merge works on. Markdown is cut where its top-level blocks begin, so that a piece is a block
/// with the blank lines after it (what comes before the first block is with it); anything else is cut at its lines. The
/// pieces joined are the text, byte for byte, whatever it holds.
enum TextPieces {
    /// - Complexity: O(the text): read once by the parser (Markdown) or once for its line ends, and once more to be hashed.
    static func of(_ text: String, kind: DocumentKind) -> [TextPiece] {
        var native = text
        // A text that comes from a text view counts in UTF-16: its bytes are made once, and an offset is then O(1) to reach.
        native.makeContiguousUTF8()
        let starts = kind == .markdown ? blockStarts(native) : lineStarts(native)
        let bytes = native.utf8
        var pieces: [TextPiece] = []
        pieces.reserveCapacity(starts.count)
        for (index, start) in starts.enumerated() {
            let end = index + 1 < starts.count ? starts[index + 1] : bytes.count
            let low = bytes.index(bytes.startIndex, offsetBy: start)
            let high = bytes.index(bytes.startIndex, offsetBy: end)
            pieces.append(TextPiece(native[low ..< high]))
        }
        return pieces
    }

    /// Where each piece begins, in bytes: 0, then the first byte of the first line of every top-level block after the first.
    private static func blockStarts(_ text: String) -> [Int] {
        guard !text.isEmpty else { return [] }
        // Read as the page reads it (the same extensions), so that a piece is a block of the page.
        let document = MarkdownParser.parse(Array(text.utf8), extensions: MarkdownLook.extensions)
        var starts = [0]
        var first = true
        for block in document.topLevelBlocks where !block.sourceRange.isEmpty {
            defer { first = false }
            let start = block.sourceRange.lowerBound
            if !first, start > starts[starts.count - 1] { starts.append(start) }
        }
        return starts
    }

    /// Where each line begins, in bytes.
    private static func lineStarts(_ text: String) -> [Int] {
        guard !text.isEmpty else { return [] }
        var starts = [0]
        var offset = 0
        let count = text.utf8.count
        for byte in text.utf8 {
            offset += 1
            if byte == 0x0A, offset < count { starts.append(offset) }
        }
        return starts
    }
}
