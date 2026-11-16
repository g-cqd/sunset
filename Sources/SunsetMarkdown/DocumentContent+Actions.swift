package import Foundation
internal import SunsetDocuments
internal import SunsetPane
internal import SunsetShell

/// What a document pane does when asked: saving, the other view beside it, a link.
extension DocumentContent {
    /// The folder of the file: what its relative pictures and links are under. A stored document has none.
    package var base: URL? {
        guard case .file(let path) = document.place else { return nil }
        return URL(fileURLWithPath: (path as NSString).deletingLastPathComponent, isDirectory: true)
    }

    /// Writes the document where it lives (Cmd-S). A failure is said in the pane and the edits stay.
    package func save() {
        do {
            try document.save()
            failure = nil
        } catch {
            failure = error.sentence
        }
    }

    /// The other view of this document in a new pane beside this one (Cmd-Option-E): the same text, so they follow each other.
    package func showBeside() {
        guard canRender else { return }
        onOpen(
            .document(DocumentContent(document: documents.open(document.place), mode: mode.other, documents: documents))
        )
    }

    /// A link of the page was followed: it opens beside this pane, and never in it.
    package func open(link url: URL) {
        guard url.isFileURL else {
            let scheme = url.scheme?.lowercased()
            return onOpen(scheme == "http" || scheme == "https" ? .web(url) : .system(url))
        }
        var isFolder: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder), !isFolder.boolValue else {
            // A folder is the Finder's; a file that is not there opens as a document that says so.
            return isFolder.boolValue ? onOpen(.system(url)) : openDocument(at: url.path)
        }
        openDocument(at: url.path)
    }

    private func openDocument(at path: String) {
        onOpen(.document(DocumentContent(document: documents.open(.file(path)), mode: nil, documents: documents)))
    }
}
