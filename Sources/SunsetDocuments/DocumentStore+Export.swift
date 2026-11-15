public import Foundation
import SunsetStorage

/// Every document out of the store as a plain file (R12 step ST-6): a copy, the documents stay.
extension DocumentStore {
    /// What an export did: how many files were written, and the titles of the documents that could not be (one that does not
    /// read, a disk that refuses).
    public struct Exported: Sendable, Equatable {
        public var written = 0
        public var failed: [String] = []
    }

    /// Writes each document's plain text in `folder`, named by its title (`Tides.md`); two of one title get a number.
    /// - Complexity: O(the documents' text).
    public func exportAll(to folder: URL) -> Exported {
        var result = Exported()
        var names = ExportFolder.Names()
        for document in documents.sorted(by: { $0.created < $1.created }) {
            guard let text = try? text(of: document.id) else {
                result.failed.append(document.title)
                continue
            }
            let name = names.next(DocumentTitle.fileName(document.title, kind: document.kind))
            let path = folder.appending(path: name).path
            do {
                try StoredFile.write(Data(text.utf8), to: path, durability: .ordered, permissions: 0o644)
                result.written += 1
            } catch {
                result.failed.append(document.title)
            }
        }
        return result
    }
}
