public import Foundation

extension Favorites {
    /// The rows a sidebar shows, top to bottom. A collapsed folder shows its row, and under it the selected entry when that entry is inside, however
    /// deep (R3): one never loses where one is.
    public func rows(selected: NodeID?) -> [Row] {
        var rows: [Row] = []
        Self.rows(of: nodes, level: 0, selected: selected, into: &rows)
        return rows
    }

    private static func rows(of nodes: [Node], level: Int, selected: NodeID?, into rows: inout [Row]) {
        for node in nodes {
            switch node {
                case .entry(let entry):
                    rows.append(Row(id: entry.id, level: level, isFolder: false))
                case .folder(let folder):
                    rows.append(Row(id: folder.id, level: level, isFolder: true))
                    if !folder.isCollapsed {
                        Self.rows(of: folder.children, level: level + 1, selected: selected, into: &rows)
                    } else if let selected, holdsEntry(selected, in: folder.children) {
                        rows.append(Row(id: selected, level: level + 1, isFolder: false))
                    }
            }
        }
    }

    private static func holdsEntry(_ id: NodeID, in nodes: [Node]) -> Bool {
        nodes.contains { node in
            switch node {
                case .entry(let entry): entry.id == id
                case .folder(let folder): holdsEntry(id, in: folder.children)
            }
        }
    }
}
