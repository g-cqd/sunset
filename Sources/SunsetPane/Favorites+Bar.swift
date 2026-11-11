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

    private static func openEntries(in nodes: [Node]) -> [NodeID] {
        nodes.flatMap { node -> [NodeID] in
            switch node {
                case .entry(let entry): entry.isOpen ? [entry.id] : []
                case .folder(let folder): openEntries(in: folder.children)
            }
        }
    }
}
