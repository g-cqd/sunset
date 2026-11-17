package import SunsetPane

/// A new tab, a new split: what is made, and with terminals off what is not (roadmap 0033).
extension TabsModel {
    /// A new tab, selected, after the current one: a terminal, or what `descriptor` says.
    package func newTab(_ descriptor: PaneDescriptor? = nil) {
        guard scopes.allows(descriptor) else {
            // With terminals off a new tab is the command bar on no tab (the owner, 2026-11-17); a kind that is off is
            // not made.
            if descriptor == nil, bar == nil { toggleBar() }
            return
        }
        let entry = workspace.selectedEntry
        register(makeContent(descriptor), as: workspace.add().pane)
        if let entry { left(entry) }
    }

    /// A new terminal beside the focused pane, in the same tab, with the keyboard; nothing when there is no focused pane.
    package func newSplit(_ edge: PaneEdge) {
        guard scopes.terminal else {
            // No terminal to put there: the bar asks which tab goes beside.
            if let target = shownPane { bar = CommandBar(purpose: .splitWith(SplitChoice(pane: target, edge: edge))) }
            return
        }
        if shownEntry != nil, let target = shownPane {
            if keeper(ofPane: target)?.addPane(beside: target, edge: edge, content: makeContent(nil)) == true {
                syncStates()
            }
            return
        }
        guard let target = workspace.selectedPane, let pane = workspace.addPane(beside: target, edge: edge) else {
            return
        }
        register(makeContent(nil), as: pane)
    }
}
