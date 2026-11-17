package import SunsetPane

extension TabsModel {
    /// Opens the bar for searching the tabs, or closes it when it is open.
    package func toggleBar() {
        guard bar == nil else {
            bar = nil
            return
        }
        var opened = CommandBar(purpose: .search)
        // In the sidebar's field while it shows one and no tab is shown (roadmap 0035 G); with a tab, large over the panes,
        // where a long address has room (the owner, 2026-11-17).
        opened.inSidebar = sidebarField != nil && workspace.selectedID == nil && workspace.selectedEntry == nil
        bar = opened
    }

    /// What a candidate of the bar is searched by: the name the tab was given, and for each of its panes the title, the second line (a directory) and
    /// what else its content says it is found by (`PaneContent.searchTerms`).
    package func fields(of item: Workspace.Item) -> [String] { space.fields(of: item) }

    /// The tabs the bar lists for its query, best first (for splitting: all but the dropped tab).
    package func barResults(_ bar: CommandBar) -> [Workspace.Item] {
        var own: Workspace.ItemID?
        if case .splitWith(let choice) = bar.purpose { own = workspace.item(containing: choice.pane)?.id }
        let items = workspace.items.filter { $0.id != own }
        let candidates = items.enumerated().map { TabSearch.Candidate(id: $0.offset, fields: fields(of: $0.element)) }
        return TabSearch.rank(query: bar.query, candidates: candidates).map { items[$0] }
    }

    /// Does what the bar was opened for with the tab `item`: selects it, or puts it on the side of the dropped tab that is opposite the edge it was dropped on
    /// (the dropped tab keeps its side and the keyboard). Closes the bar.
    package func accept(_ item: Workspace.ItemID, in bar: CommandBar) {
        self.bar = nil
        switch bar.purpose {
            case .search: select(item: item)
            case .splitWith(let choice): complete(choice, with: item)
        }
    }
}
