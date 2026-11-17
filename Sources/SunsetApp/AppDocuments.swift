import Foundation
import SunsetConfig
import SunsetDocuments
import SunsetShell
import SunsetStorage

/// The documents of the store as the sidebars reach them (roadmap 0030 step ST-5): the shell lists, makes and deletes them
/// through a `DocumentShelf`, which is filled here from `AppStorage`.
@MainActor
enum AppDocuments {
    /// Says to `shelf` how the store's documents are listed, made and deleted.
    static func wire(_ shelf: DocumentShelf) {
        shelf.available = { AppStorage.shared.documents != nil }
        shelf.list = { (AppStorage.shared.documents?.documents ?? []).map(ShelfDocument.init) }
        shelf.create = { try? AppStorage.shared.documents?.create().id }
        shelf.delete = { delete($0) }
        let recent = AppStorage.shared.recentFiles
        shelf.files = { recent.entries.map { ShelfDocument(file: $0.path, opened: $0.opened) } }
        shelf.noteFile = { recent.note($0) }
        shelf.forgetFile = { recent.remove($0) }
    }

    /// Deletes a document at once (the owner, ST-5): what was typed and not saved is saved first, so that the plain text put
    /// in the Mac's Trash is the latest; then its panes close in every window.
    /// - Parameter id: the document.
    /// - Returns: whether it was deleted; when not, it is said (`StorageProblems`) and nothing closes.
    static func delete(_ id: UUID) -> Bool {
        let storage = AppStorage.shared
        guard let store = storage.documents else { return false }
        if let open = storage.openDocuments.document(at: .stored(id)), open.isEdited { try? open.save() }
        let title = store.documents.first { $0.id == id }?.title ?? "Untitled"
        do {
            try store.delete(id)
        } catch {
            let what = "The document \(title)"
            StorageProblems.shared.report(
                StorageProblem(what: what, path: storage.places.documents, movedTo: nil, kind: .notRemoved)
            )
            return false
        }
        // It is gone: nothing typed in the moment between is written back, which would make it again.
        if let open = storage.openDocuments.document(at: .stored(id)) { storage.openDocuments.discard(open) }
        for (_, tabs) in TabRegistry.shared.allWindows() { tabs.closePanes(showing: id) }
        return true
    }

    /// When a file is written by itself, and how sources look, from the settings (`documents.saveAfter`,
    /// `documents.saveOnFocusLoss`, `documents.largerHeadings`).
    static func apply(_ settings: Configuration.Documents) {
        let asked = DocumentAutosave(seconds: settings.saveAfter, onFocusLoss: settings.saveOnFocusLoss)
        AppStorage.shared.openDocuments.autosave.fileDelay = asked.fileDelay
        AppStorage.shared.openDocuments.autosave.onFocusLoss = asked.onFocusLoss
        AppStorage.shared.openDocuments.look.largerHeadings = settings.largerHeadings
    }
}

extension ShelfDocument {
    init(_ stored: StoredDocument) {
        let kind: Kind =
            switch stored.kind {
                case .markdown: .markdown
                case .mermaid: .diagram
                case .text: .text
            }
        self.init(id: stored.id, title: stored.title, kind: kind, created: stored.created, modified: stored.modified)
    }
}
