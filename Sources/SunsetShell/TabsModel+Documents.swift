package import Foundation
package import SunsetPane

/// The documents of the store as tabs of this window (roadmap 0030 step ST-5, 0031). A document is opened from a list of them
/// (the Library, the panel opposite the tabs) and is then a tab like any other, among the tabs: it is moved, split, kept and
/// closed as they are (the owner, 2026-11-15). The document stays in the store when its tab closes.
extension TabsModel {
    /// The stored document the pane shows, when it shows one.
    package func document(in pane: PaneID) -> UUID? {
        content(pane)?.descriptor.storedDocument
    }

    /// A click on `document` in a list: shown where it already is in this window's tabs, with the keyboard; else opened as a
    /// new tab, where a new tab goes.
    package func show(document: UUID) {
        let pane = workspace.allPanes.first { self.document(in: $0) == document }
        guard let pane, let item = workspace.item(containing: pane) else { return newTab(.document(stored: document)) }
        select(item: item.id)
        focus(pane)
    }

    /// A tab on `document` at `index` among the tabs, shown or not, whether or not another shows it; its id.
    @discardableResult
    package func openTab(document: UUID, at index: Int, show: Bool) -> Workspace.ItemID {
        let entry = workspace.selectedEntry
        let pane = workspace.addTab(at: index, show: show)
        register(makeContent(.document(stored: document)), as: pane)
        if show, let entry { left(entry) }
        return workspace.item(containing: pane)?.id ?? Workspace.ItemID()
    }

    /// A new document, opened as a tab. Nothing when none can be kept in this run.
    package func newDocument() {
        if let made = shelf.create() { show(document: made) }
    }

    /// Deletes `document` at once (the owner, ST-5): the shelf puts it away (what was typed is saved into it first), then its
    /// panes in this window close without asking.
    package func delete(document: UUID) {
        if shelf.delete(document) { closePanes(showing: document) }
    }

    /// Closes every pane of this window that shows `document`, without asking: the document is gone.
    package func closePanes(showing document: UUID) {
        for pane in workspace.allPanes where self.document(in: pane) == document { close(pane: pane) }
    }

    /// What is dragged, a document become a tab of this window (not shown, at the end) so that it is dropped as a tab is.
    func takeDocumentDrag() {
        guard case .document(let id) = dragged else { return }
        dragged = .item(openTab(document: id, at: workspace.count, show: false))
    }
}
