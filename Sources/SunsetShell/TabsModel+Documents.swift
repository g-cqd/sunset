package import Foundation
package import SunsetPane

/// The documents of the store as tabs of this window (roadmap 0030 step ST-5, 0031). A document opened from its row is a tab
/// like any other that is drawn on that row, under the Documents heading, instead of among the tabs (`Workspace.Item.shelved`).
extension TabsModel {
    /// The stored document the pane shows, when it shows one.
    package func document(in pane: PaneID) -> UUID? { content(pane)?.descriptor.storedDocument }

    private func shows(_ item: Workspace.Item, _ document: UUID) -> Bool {
        item.panes.contains { self.document(in: $0) == document }
    }

    /// The tab drawn on the row of `document` under the Documents heading: it is open in place.
    package func shelved(_ document: UUID) -> Workspace.Item? {
        workspace.items.first { $0.shelved && shows($0, document) }
    }

    /// The tabs listed among the tabs: all of them, but those drawn on their document's row while the heading shows
    /// (`shelf`). A tab on a row that no longer shows a document is among the tabs again.
    package func listedItems(shelf: Bool) -> [Workspace.Item] {
        guard shelf else { return workspace.items }
        return workspace.items.filter { item in !item.shelved || !item.panes.contains { document(in: $0) != nil } }
    }

    /// A click on the row of `document` under the heading: its tab is shown, opened on the row first when it is not open.
    package func open(document: UUID) {
        if let item = shelved(document) { return select(item: item.id) }
        let item = openTab(document: document, at: workspace.count, show: true)
        change { $0.shelve(item: item, true) }
    }

    /// A click on `document` in a section of the Library or of the opposite panel: shown where it already is in this window,
    /// else opened on its row.
    package func show(document: UUID) {
        guard let item = workspace.items.first(where: { shows($0, document) }) else { return open(document: document) }
        select(item: item.id)
        if let pane = item.panes.first(where: { self.document(in: $0) == document }) { focus(pane) }
    }

    /// A tab on `document` at `index` among the tabs, shown or not; its id.
    @discardableResult
    package func openTab(document: UUID, at index: Int, show: Bool) -> Workspace.ItemID {
        let entry = workspace.selectedEntry
        let pane = workspace.addTab(at: index, show: show)
        register(makeContent(.document(stored: document)), as: pane)
        if show, let entry { left(entry) }
        return workspace.item(containing: pane)?.id ?? Workspace.ItemID()
    }

    /// The minus of an open document's row: its tab closes (asking first when something would be lost), the document stays.
    package func unload(document: UUID) {
        if let item = shelved(document) { close(item: item.id) }
    }

    /// The + of the Documents heading: a new document, opened in place. Nothing when none can be kept in this run.
    package func newDocument() {
        if let made = shelf.create() { open(document: made) }
    }

    /// Deletes `document` at once (the owner, ST-5): its panes in this window close without asking, then the shelf puts it away.
    package func delete(document: UUID) {
        for pane in workspace.allPanes where self.document(in: pane) == document { close(pane: pane) }
        shelf.delete(document)
    }

    /// What is dragged, a document become a tab of this window (not shown, at the end) so that it is dropped as a tab is.
    func takeDocumentDrag() {
        guard case .document(let id) = dragged else { return }
        dragged = .item(openTab(document: id, at: workspace.count, show: false))
    }
}
