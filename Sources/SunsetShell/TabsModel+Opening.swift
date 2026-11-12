import Foundation
package import SunsetPane

/// Content opened by other content (a page's link, a terminal's Cmd-click): placed next to the pane of its opener.
extension TabsModel {
    /// The pane that holds `content`, in this window's tabs or in an open kept entry.
    package func pane(of content: any PaneContent) -> PaneID? {
        contents.first { $0.value === content }?.key ?? favorites.contents.first { $0.value === content }?.key
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
        if favorites.favorites.entry(containing: target) != nil {
            if favorites.addPane(beside: target, edge: edge, content: content) { syncStates() }
            return
        }
        guard let pane = workspace.addPane(beside: target, edge: edge) else { return }
        register(content, as: pane)
    }
}
