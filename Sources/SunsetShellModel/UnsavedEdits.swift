/// The unsaved edits of what a pane shows, as the tabs see them ("Closing with unsaved edits asks Save, Don't Save,
/// Cancel"). Several panes can show one document: it is lost only when the panes that close are all of them.
@MainActor
package struct UnsavedEdits {
    /// The document, the same for every pane that shows it.
    package let id: ObjectIdentifier
    package let title: String
    /// How many panes show it, in every window.
    package let paneCount: Int
    /// Writes it; false when it could not be written (the pane then says why).
    package let save: () -> Bool
    /// The person gave the edits up.
    package let discard: () -> Void

    package init(
        id: ObjectIdentifier,
        title: String,
        paneCount: Int,
        save: @escaping () -> Bool,
        discard: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.paneCount = paneCount
        self.save = save
        self.discard = discard
    }
}
