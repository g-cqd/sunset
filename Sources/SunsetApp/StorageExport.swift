import AppKit
import SunsetDocuments
import SunsetStorage
import SunsetWeb

/// Export All (R12, roadmap 0030 step ST-6): every document as a plain file, the history as CSV and the session as readable
/// JSON, in a dated folder of the folder the person chooses (`ExportAll`). A copy: nothing leaves the store.
@MainActor
enum StorageExport {
    /// Asks where, then exports there; nil when the person cancelled.
    static func ask() -> ExportAll.Outcome? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export"
        panel.message = "A folder named Sunset Export and the date is made in the folder you choose."
        guard panel.runModal() == .OK, let parent = panel.url else { return nil }
        return export(into: parent)
    }

    static func export(into parent: URL, storage: AppStorage = .shared) -> ExportAll.Outcome {
        ExportAll.run(into: parent) { folder in
            [documents(in: folder, storage), history(in: folder), session(in: folder)]
        }
    }

    private static func documents(in folder: URL, _ storage: AppStorage) -> ExportAll.Step? {
        guard let store = storage.documents, !store.documents.isEmpty else { return nil }
        // What was typed and not saved yet is saved first, so that the export holds the latest.
        for document in store.documents {
            if let open = storage.openDocuments.document(at: .stored(document.id)), open.isEdited { try? open.save() }
        }
        let result = store.exportAll(to: folder.appending(path: "Documents", directoryHint: .isDirectory))
        return ExportAll.Step(
            said: result.written == 0 ? nil : (result.written == 1 ? "1 document" : "\(result.written) documents"),
            problem: result.failed.isEmpty ? nil : "Not exported: " + result.failed.joined(separator: ", ") + "."
        )
    }

    private static func history(in folder: URL) -> ExportAll.Step? {
        guard let history = AppHistory.shared, history.count > 0 else { return nil }
        let pages = history.count == 1 ? "1 page" : "\(history.count) pages"
        return ExportAll.file(
            Data(history.csv().utf8),
            named: "History.csv",
            in: folder,
            said: "the history (\(pages))"
        )
    }

    private static func session(in folder: URL) -> ExportAll.Step? {
        SessionStore.shared.readable()
            .map { ExportAll.file($0, named: "Session.json", in: folder, said: "the session") }
    }
}
