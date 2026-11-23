package import Foundation
internal import SunsetPane

/// The tab menu's Duplicate, Copy Address and Share (n136), for the rows it acts on.
extension TabsModel {
    /// Copies each tab among `rows` right after it, its splits and what each pane shows (a content of its own, made from
    /// the same descriptor); the copy of a single tab is shown.
    package func duplicate(_ rows: [RowTarget]) {
        let items = rows.compactMap { row -> Workspace.ItemID? in
            if case .tab(let id) = row { id } else { nil }
        }
        for id in items {
            let descriptors = workspace.items.first { $0.id == id }?.panes
                .map { (pane: $0, made: contents[$0]?.descriptor) }
            let names = workspace.duplicate(id, show: items.count == 1)
            for (pane, descriptor) in descriptors ?? [] {
                guard let copy = names[pane] else { continue }
                register(makeContent(descriptor.flatMap { scopes.allows($0) ? $0 : nil }), as: copy)
            }
        }
        if items.count == 1 { syncStates() }
        clearMarks()
    }

    /// The addresses of the pages among `rows`, in order: a tab's panes, a kept entry's (what it shows when open, what it
    /// starts from when not), every entry of a folder.
    package func addresses(of rows: [RowTarget]) -> [URL] {
        rows.flatMap { row -> [PaneDescriptor] in
            switch row {
                case .tab(let id):
                    let panes = workspace.items.first { $0.id == id }?.panes ?? []
                    return panes.compactMap { contents[$0]?.descriptor }
                case .node(let id):
                    let keeper = keeper(of: id)
                    return keeper.favorites.entries(under: id)
                        .flatMap { entry in
                            guard let open = entry.open else {
                                return entry.home.layout.panes.compactMap { entry.home.contents[$0] }
                            }
                            return open.panes.compactMap { keeper.contents[$0]?.descriptor }
                        }
            }
        }
        .compactMap { descriptor in
            descriptor.kind == PaneDescriptor.webKind ? descriptor.state["url"].flatMap { URL(string: $0) } : nil
        }
    }
}
