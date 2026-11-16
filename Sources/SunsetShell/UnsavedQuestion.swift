package import SunsetPane

/// What a window asks before something closes with unsaved edits: the documents that would be lost, and what was closing.
@MainActor
package struct UnsavedQuestion {
    package let documents: [UnsavedEdits]
    /// A pane that shows each, in the same order: where a save that failed is shown.
    let holders: [PaneID]
    /// What was asked for, done once the edits are saved or given up.
    let proceed: () -> Void

    /// The sentence of the sheet.
    package var title: String {
        guard documents.count != 1, !documents.isEmpty else {
            return "Do you want to save the changes made to \(documents.first?.title ?? "this document")?"
        }
        return "Do you want to save the changes made to \(documents.count) documents?"
    }

    package var detail: String { "Your changes will be lost if you don\u{2019}t save them." }
    package var saveLabel: String { documents.count > 1 ? "Save All" : "Save" }
}
