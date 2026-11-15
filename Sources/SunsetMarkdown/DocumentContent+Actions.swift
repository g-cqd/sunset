package import Foundation
internal import SunsetDocuments
package import SunsetPane
package import SunsetShell

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
            switch error {
                case .readOnly: failure = "This document was not read, so it is not written."
                case .write(let reason): failure = "Not saved: \(reason)."
            }
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

extension DocumentContent {
    /// What quitting would lose of the documents: each edited one once, however many panes show it. Closing a pane loses
    /// nothing while another shows the document (`closeWarning`); quitting closes them all.
    /// - Parameter panes: every pane of the app, with its id when it is in a window.
    /// - Returns: a loss per edited document, at the first pane found that shows it.
    package static func quitLosses(in panes: [(PaneID?, any PaneContent)]) -> [QuitLoss] {
        var seen: Set<ObjectIdentifier> = []
        var losses: [QuitLoss] = []
        for (pane, content) in panes {
            guard let content = content as? Self, content.document.isEdited,
                seen.insert(ObjectIdentifier(content.document)).inserted
            else { continue }
            losses.append(QuitLoss(kind: .document, text: "\(content.title) has edits that are not saved.", pane: pane))
        }
        return losses
    }
}
