import Foundation
package import SunsetPane

/// Content opened by other content (a page's link, a terminal's Cmd-click): placed next to the pane of its opener.
extension TabsModel {
    /// The pane that holds `content`, in this window's tabs or in an open kept entry.
    package func pane(of content: any PaneContent) -> PaneID? {
        contents.first { $0.value === content }?.key ?? favorites.contents.first { $0.value === content }?.key
            ?? pinned?.contents.first { $0.value === content }?.key
    }

    /// Shows the tab, or the kept entry, that holds `content`, with the keyboard in its pane (a page's notification clicked).
    /// False when this window holds it nowhere.
    @discardableResult
    package func reveal(_ content: any PaneContent) -> Bool {
        guard let pane = pane(of: content) else { return false }
        if let item = workspace.item(containing: pane) {
            select(item: item.id)
        } else if let entry = keeper(ofPane: pane)?.favorites.entry(containing: pane) {
            select(entry: entry.id)
        } else {
            return false
        }
        focus(pane)
        return true
    }

    /// The content of the kind `kind` in this window's tabs or in the kept entry it shows: for a kind there is one of in a window
    /// (the settings).
    package func single(kind: String) -> (any PaneContent)? {
        let panes = workspace.allPanes + (shownEntry?.open?.panes ?? [])
        return panes.lazy.compactMap { self.content($0) }.first { $0.descriptor.kind == kind }
    }

    /// Shows the one content of the descriptor's kind, with the keyboard: the one that is there, else a new tab of it.
    /// - Returns: the content shown.
    @discardableResult
    package func showSingle(_ descriptor: PaneDescriptor) -> (any PaneContent)? {
        guard let found = single(kind: descriptor.kind), let pane = pane(of: found) else {
            newTab(descriptor)
            return selectedContent
        }
        if let item = workspace.item(containing: pane) { select(item: item.id) }
        focus(pane)
        return found
    }

    /// A tab holding `content`, right after the tab of `opener` (or after the selected tab when the opener is in no tab of this window), shown or not.
    package func insertTab(_ content: any PaneContent, after opener: any PaneContent, show: Bool) {
        let index =
            pane(of: opener).flatMap { pane in workspace.items.firstIndex { $0.layout.contains(pane) } }.map { $0 + 1 }
            ?? workspace.selectedIndex.map { $0 + 1 } ?? workspace.count
        let pane = workspace.addTab(at: index, show: show)
        register(content, as: pane)
        onChange()
    }

    /// `content` in a new pane on `edge` of the pane of `opener` (a kept entry's pane too), with the keyboard.
    package func split(_ edge: PaneEdge, with content: any PaneContent, beside opener: any PaneContent) {
        guard let target = pane(of: opener) else { return insertTab(content, after: opener, show: true) }
        if let favorites = keeper(ofPane: target) {
            if favorites.addPane(beside: target, edge: edge, content: content) { syncStates() }
            return
        }
        guard let pane = workspace.addPane(beside: target, edge: edge) else { return }
        register(content, as: pane)
    }
}
