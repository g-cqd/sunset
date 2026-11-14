import Foundation
import SunsetStorage

/// The index against the files (R12 step ST-4): the files are what is true.
extension DocumentStore {
    /// Reads the index, then the folder: a file the index does not know, or knows with another size or time, is opened and
    /// indexed again; an entry without its file is dropped. A file that does not open is set aside and said (one sealed with
    /// another key is left, and said). With a lost index every file is opened: the index is rebuilt.
    /// - Complexity: O(the number of documents) when the index agrees; O(the bytes of the documents it must open) otherwise.
    func reconcile() {
        var known: [UUID: StoredDocument] = [:]
        for row in index?.all().rows ?? [] {
            if let document = try? JSONDecoder().decode(StoredDocument.self, from: row.payload) {
                known[document.id] = document
            }
        }
        var found: [StoredDocument] = []
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        for name in names where name.hasSuffix(".sealed") {
            guard let id = UUID(uuidString: String(name.dropLast(".sealed".count))) else { continue }
            let attributes = try? FileManager.default.attributesOfItem(atPath: path(id))
            let stamp = (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970
            let last = known.removeValue(forKey: id)
            if let last, last.size == attributes?[.size] as? Int, last.stamp == stamp {
                found.append(last)
            } else if let document = read(id, lastTitle: last?.title) {
                if let data = try? JSONEncoder().encode(document) {
                    index?.put(id.uuidString, payload: data, sort: document.modified.timeIntervalSince1970)
                }
                found.append(document)
            } else {
                index?.remove(id.uuidString)
            }
        }
        // What the index still holds has no file.
        for id in known.keys { index?.remove(id.uuidString) }
        documents = found.sorted { $0.modified > $1.modified }
    }

    /// Opens a document's file for the index; says what is wrong with one that does not open.
    private func read(_ id: UUID, lastTitle: String?) -> StoredDocument? {
        guard let bytes = FileManager.default.contents(atPath: path(id)) else { return nil }
        let what = lastTitle.map { "The document \u{201C}\($0)\u{201D}" } ?? "A document"
        do {
            return entry(for: try SealedDocument(bytes, seal: seal, id: id), id: id)
        } catch .otherKey {
            problems.report(StorageProblem(what: what, path: path(id), movedTo: nil, kind: .locked))
        } catch {
            problems.report(StorageProblem(what: what, path: path(id), movedTo: StoredFile.moveAside(path(id))))
        }
        return nil
    }
}
