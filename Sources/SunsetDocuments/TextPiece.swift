/// One piece of a text that a merge works on (roadmap 0023 step M-e): a top-level block of Markdown with the blank lines
/// after it, or a line. Two pieces are the same when their bytes are: two spellings of one character (composed, decomposed)
/// are not, since a file that changed from one to the other did change.
struct TextPiece: Hashable, Sendable {
    let text: Substring
    private let digest: Int

    /// - Complexity: O(the piece's bytes).
    init(_ text: Substring) {
        self.text = text
        var hasher = Hasher()
        let hashed: Void? = unsafe text.utf8.withContiguousStorageIfAvailable { bytes in
            unsafe hasher.combine(bytes: UnsafeRawBufferPointer(bytes))
        }
        if hashed == nil {
            for byte in text.utf8 { hasher.combine(byte) }
        }
        digest = hasher.finalize()
    }

    static func == (first: TextPiece, second: TextPiece) -> Bool {
        first.digest == second.digest && first.text.utf8.elementsEqual(second.text.utf8)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(digest) }
}
