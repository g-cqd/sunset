public import Foundation
public import Observation
public import SunsetRuntime
public import SunsetStorage

/// The documents that live in Sunset (R12, roadmap 0030 step ST-4): one sealed file each in a folder, written whole or not at
/// all, and an index of what the library shows (title, kind, dates), which holds nothing that the files do not: it is rebuilt
/// from them when it is lost, and follows them when it disagrees. One damaged file loses one document, and is set aside and
/// said. Other tools cannot read these files; a document leaves the store as plain text (`delete`, `move`).
@MainActor @Observable
public final class DocumentStore {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    public var runtime = Runtime.live

    /// The latest changed first.
    public internal(set) var documents: [StoredDocument] = []

    @ObservationIgnored let folder: String
    @ObservationIgnored let seal: Seal
    @ObservationIgnored let index: SealedTable?
    @ObservationIgnored let problems: StorageProblems
    /// Puts a plain file away: the Mac's Trash for the person's own setup (the owner, R12), removal for a named one.
    @ObservationIgnored let discard: (URL) throws -> Void

    /// Opens the store on `folder`. Without a `library` (the index's database) the index is in memory only, and is rebuilt
    /// from the files at each open. `discard` puts a plain file away.
    public init(
        folder: String,
        library: StateDatabase?,
        key: StorageKey,
        problems: StorageProblems = .shared,
        discard: @escaping (URL) throws -> Void
    ) {
        self.folder = folder
        seal = Seal(key: key, purpose: .document)
        index = library?.table("documents")
        self.problems = problems
        self.discard = discard
        reconcile()
    }

    func path(_ id: UUID) -> String {
        folder + "/" + id.uuidString + ".sealed"
    }

    /// A new document, kept at once.
    @discardableResult
    public func create(kind: DocumentKind = .markdown, text: String = "") throws(DocumentStoreFailure) -> StoredDocument
    {
        let id = UUID()
        return try write(SealedDocument(kind: kind, created: runtime.now(), text: text), id: id)
    }

    public func text(of id: UUID) throws(DocumentStoreFailure) -> String {
        try file(id).text
    }

    /// Keeps the document's text: sealed, forced to the disk, in place of the old file or not at all.
    public func save(_ text: String, to id: UUID) throws(DocumentStoreFailure) {
        var file = try file(id)
        file.text = text
        try write(file, id: id)
    }

    /// Puts the document away as plain text under its name (the Mac's Trash), and takes it out of the store.
    public func delete(_ id: UUID) throws(DocumentStoreFailure) {
        guard let document = documents.first(where: { $0.id == id }) else { throw .missing }
        let text = try text(of: id)
        // Out of the store's folder by way of a plain file made for the purpose: the sealed one is no use in the Trash.
        let name = DocumentTitle.fileName(document.title, kind: document.kind)
        let outgoing = folder + "/.outgoing-" + UUID().uuidString
        do {
            try StoredFile.write(Data(text.utf8), to: outgoing + "/" + name, durability: .forced, permissions: 0o644)
            try discard(URL(fileURLWithPath: outgoing + "/" + name))
        } catch {
            try? FileManager.default.removeItem(atPath: outgoing)
            throw .write
        }
        try? FileManager.default.removeItem(atPath: outgoing)
        forget(id)
    }

    /// Writes the document's plain text at `url` (a file of the person's), and takes it out of the store.
    public func move(_ id: UUID, to url: URL) throws(DocumentStoreFailure) {
        let text = try text(of: id)
        do {
            try StoredFile.write(Data(text.utf8), to: url.path, durability: .forced, permissions: 0o644)
        } catch {
            throw .write
        }
        forget(id)
    }

    private func forget(_ id: UUID) {
        try? FileManager.default.removeItem(atPath: path(id))
        index?.remove(id.uuidString)
        documents.removeAll { $0.id == id }
    }

    private func file(_ id: UUID) throws(DocumentStoreFailure) -> SealedDocument {
        guard let bytes = FileManager.default.contents(atPath: path(id)) else { throw .missing }
        do {
            return try SealedDocument(bytes, seal: seal, id: id)
        } catch {
            throw .unreadable
        }
    }

    @discardableResult
    private func write(_ file: SealedDocument, id: UUID) throws(DocumentStoreFailure) -> StoredDocument {
        do {
            try StoredFile.write(try file.sealed(seal, id: id), to: path(id), durability: .forced)
        } catch {
            throw .write
        }
        let document = entry(for: file, id: id)
        keep(document)
        return document
    }

    /// What the index holds of a document whose file was just written or read.
    func entry(for file: SealedDocument, id: UUID) -> StoredDocument {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path(id))
        let changed = (attributes?[.modificationDate] as? Date) ?? runtime.now()
        return StoredDocument(
            id: id,
            title: DocumentTitle.of(file.text, kind: file.kind),
            kind: file.kind,
            created: file.created,
            modified: changed,
            size: (attributes?[.size] as? Int) ?? 0,
            stamp: changed.timeIntervalSince1970
        )
    }

    func keep(_ document: StoredDocument) {
        documents.removeAll { $0.id == document.id }
        let place = documents.firstIndex { $0.modified <= document.modified } ?? documents.count
        documents.insert(document, at: place)
        if let data = try? JSONEncoder().encode(document) {
            index?.put(document.id.uuidString, payload: data, sort: document.modified.timeIntervalSince1970)
        }
    }
}
