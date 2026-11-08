import SunsetPane

extension TabsModel {
    /// Opens the bar for searching the tabs, or closes it when it is open.
    func toggleBar() { bar = bar == nil ? CommandBar(purpose: .search) : nil }

    /// What a candidate of the bar is searched by: the title, the directory and the program in front of each of its panes.
    func fields(of item: Workspace.Item) -> [String] {
        item.panes.flatMap { pane -> [String] in
            guard let model = models[pane] else { return [] }
            return [model.title, model.directory ?? "", model.foregroundCommand ?? ""].filter { !$0.isEmpty }
        }
    }

    /// The tabs the bar lists for its query, best first (for splitting: all but the dropped tab).
    func barResults(_ bar: CommandBar) -> [Workspace.Item] {
        var own: Workspace.ItemID?
        if case .splitWith(let choice) = bar.purpose { own = workspace.item(containing: choice.pane)?.id }
        let items = workspace.items.filter { $0.id != own }
        let candidates = items.enumerated().map { TabSearch.Candidate(id: $0.offset, fields: fields(of: $0.element)) }
        return TabSearch.rank(query: bar.query, candidates: candidates).map { items[$0] }
    }

    /// Does what the bar was opened for with the tab `item`: selects it, or puts it on the side of the dropped tab that is opposite the edge it was dropped on
    /// (the dropped tab keeps its side and the keyboard). Closes the bar.
    func accept(_ item: Workspace.ItemID, in bar: CommandBar) {
        self.bar = nil
        switch bar.purpose {
            case .search: select(item: item)
            case .splitWith(let choice): complete(choice, with: item)
        }
    }
}
