extension Favorites {
    /// What the built-in tab bar shows of the Favorites (R3 step f): top-level open entries, and each top-level folder with the open entries it holds at any
    /// depth (deeper folders flattened into it); a collapsed folder hides its entries, unless one of them is `selected`. Entries that are not open are never
    /// shown; a folder holding none that is open is left out.
    public enum BarItem: Sendable, Hashable {
        case entry(NodeID)
        case folder(NodeID, openCount: Int)
    }

    public func barItems(selected: NodeID?) -> [BarItem] {
        nodes.flatMap { node -> [BarItem] in
            switch node {
                case .entry(let entry):
                    return entry.isOpen ? [.entry(entry.id)] : []
                case .folder(let folder):
                    let open = Self.openEntries(in: folder.children)
                    guard !open.isEmpty else { return [] }
                    let shown = folder.isCollapsed ? open.filter { $0 == selected } : open
                    return [.folder(folder.id, openCount: open.count)] + shown.map(BarItem.entry)
            }
        }
    }

    /// The pinned tabs of the tab bar's row of capsules (owner, 2026-11-13): every top-level entry, open or not, and each top-level
    /// folder with every entry it holds at any depth; a collapsed folder hides its entries, unless one of them is `selected`. An
    /// empty folder is left out.
    public func pinnedItems(selected: NodeID?) -> [BarItem] {
        nodes.flatMap { node -> [BarItem] in
            switch node {
                case .entry(let entry):
                    return [.entry(entry.id)]
                case .folder(let folder):
                    let all = Self.allEntries(in: folder.children)
                    guard !all.isEmpty else { return [] }
                    let open = Self.openEntries(in: folder.children)
                    let shown = folder.isCollapsed ? all.filter { $0 == selected } : all
                    return [.folder(folder.id, openCount: open.count)] + shown.map(BarItem.entry)
            }
        }
    }

    private static func allEntries(in nodes: [Node]) -> [NodeID] {
        nodes.flatMap { node -> [NodeID] in
            switch node {
                case .entry(let entry): [entry.id]
                case .folder(let folder): allEntries(in: folder.children)
            }
        }
    }

    private static func openEntries(in nodes: [Node]) -> [NodeID] {
        nodes.flatMap { node -> [NodeID] in
            switch node {
                case .entry(let entry): entry.isOpen ? [entry.id] : []
                case .folder(let folder): openEntries(in: folder.children)
            }
        }
    }
}
