package import SunsetPane

/// A new tab, a new split: what is made, and with terminals off what is not.
extension TabsModel {
    /// A new tab after the current one: a terminal, or what `descriptor` says; selected when `show` is true.
    package func newTab(_ descriptor: PaneDescriptor? = nil, show: Bool = true) {
        guard scopes.allows(descriptor) else {
            // With terminals off a new tab is the command bar on no tab; a kind that is off is not made.
            if descriptor == nil, bar == nil { toggleBar() }
            return
        }
        let entry = workspace.selectedEntry
        let made = makeContent(descriptor)
        if show {
            register(made, as: workspace.add().pane)
            if let entry { left(entry) }
        } else {
            let index = workspace.selectedIndex.map { $0 + 1 } ?? workspace.count
            register(made, as: workspace.addTab(at: index, show: false))
        }
        asksAddress(made)
    }

    /// What `descriptor` says (a terminal by default) beside the focused pane, in the same tab, with the keyboard; nothing
    /// when there is no focused pane. A page with nowhere to go asks for its address, as a new tab's does.
    package func newSplit(_ edge: PaneEdge, _ descriptor: PaneDescriptor? = nil) {
        guard scopes.allows(descriptor) else {
            // Nothing of that kind to put there: the bar asks which tab goes beside.
            if let target = shownPane { bar = CommandBar(purpose: .splitWith(SplitChoice(pane: target, edge: edge))) }
            return
        }
        if shownEntry != nil, let target = shownPane {
            let made = makeContent(descriptor)
            if keeper(ofPane: target)?.addPane(beside: target, edge: edge, content: made) == true {
                syncStates()
                asksAddress(made)
            }
            return
        }
        guard let target = workspace.selectedPane, let pane = workspace.addPane(beside: target, edge: edge) else {
            return
        }
        let made = makeContent(descriptor)
        register(made, as: pane)
        asksAddress(made)
    }

    /// A page with nowhere to go yet: the command bar, to type an address or a search. Asking is the action's that made
    /// it; a page's view asks for nothing by itself.
    private func asksAddress(_ made: any PaneContent) {
        guard made.isBlankPage, bar == nil else { return }
        toggleBar()
        bar?.forNewPage = true
    }
}
