package import SunsetDocuments
package import SunsetPane
package import SunsetShell

/// The edits of a document when something is about to close them (R6, roadmap 0023 step M-d).
extension DocumentContent {
    /// The edits closing this pane could lose, with how many panes show the document: the tabs ask only when the ones that
    /// close are all of them. A document of Sunset's own store keeps itself, so it is asked about only once that has failed.
    package var unsaved: UnsavedEdits? {
        guard document.isEdited, !document.keepsItself else { return nil }
        return UnsavedEdits(
            id: ObjectIdentifier(document),
            title: title,
            paneCount: document.paneCount,
            save: { [self] in
                save()
                return failure == nil && !document.isEdited
            },
            discard: { [self] in documents.discard(document) }
        )
    }

    /// What quitting would lose of the documents: each edited one once, however many panes show it, and the ones no pane
    /// shows any more (a window that went without asking). Closing a pane loses nothing while another shows the document;
    /// quitting closes them all.
    /// - Parameters:
    ///   - documents: the documents that are open.
    ///   - panes: every pane of the app, with its id when it is in a window.
    /// - Returns: a loss per edited document, at the first pane found that shows it, else with its file.
    package static func quitLosses(of documents: OpenDocuments, in panes: [(PaneID?, any PaneContent)]) -> [QuitLoss] {
        var shown: [ObjectIdentifier: PaneID?] = [:]
        for (pane, content) in panes {
            guard let content = content as? Self else { continue }
            let id = ObjectIdentifier(content.document)
            if shown[id] == nil { shown[id] = .some(pane) }
        }
        return documents.edited.map { document in
            var file: String?
            if case .file(let path) = document.place { file = path }
            return QuitLoss(
                kind: .document,
                text: "\(document.title) has edits that are not saved.",
                pane: shown[ObjectIdentifier(document)] ?? nil,
                file: file
            )
        }
    }
}
