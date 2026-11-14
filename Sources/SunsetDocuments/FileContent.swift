internal import Foundation

/// A file as it was read for a document: its text, what is wrong with it, and a mark of its bytes.
struct FileContent: Sendable {
    /// The bytes' length and hash: enough to tell that a change on disk says what is already known.
    struct Mark: Sendable, Equatable {
        let count: Int
        let hash: Int

        /// - Complexity: O(the bytes): every one is hashed (not left to `Data`'s own hash, which need not read them all).
        init(_ data: Data) {
            count = data.count
            var hasher = Hasher()
            unsafe data.withUnsafeBytes { unsafe hasher.combine(bytes: $0) }
            hash = hasher.finalize()
        }
    }

    var text = ""
    var problem: OpenDocumentProblem?
    var mark: Mark?

    /// - Complexity: O(the file's bytes).
    static func read(_ path: String) -> FileContent {
        guard FileManager.default.fileExists(atPath: path) else { return FileContent(problem: .missing) }
        guard let data = FileManager.default.contents(atPath: path) else { return FileContent(problem: .unreadable) }
        let mark = Mark(data)
        if let text = String(data: data, encoding: .utf8) { return FileContent(text: text, mark: mark) }
        // Not UTF-8: shown with what does not decode replaced, and never written back.
        return FileContent(text: String(decoding: data, as: UTF8.self), problem: .notText, mark: mark)
    }

    /// The same, off the caller's actor: a long file read again after a change does not hold the main actor.
    @concurrent
    static func readConcurrently(_ path: String) async -> FileContent { read(path) }
}
