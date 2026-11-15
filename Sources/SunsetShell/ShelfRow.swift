package import SunsetPane

/// A row under the Documents heading among the tabs: a document, and its tab while it is open in place.
package struct ShelfRow: Identifiable {
    package let document: ShelfDocument
    package let item: Workspace.Item?

    package var id: ShelfDocument.ID { document.id }
}
