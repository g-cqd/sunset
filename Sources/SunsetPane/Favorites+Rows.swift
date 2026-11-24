public import Foundation

extension Favorites {
    /// The rows a sidebar shows, top to bottom. A collapsed folder shows its row, under it any open entries inside when
    /// `showOpenInCollapsed` is on (so open tabs are never hidden out of sight), and the selected entry when it is
    /// inside, however deep: one never loses where one is.
    public func rows(selected: NodeID?, showOpenInCollapsed: Bool = true) -> [Row] {
        var rows: [Row] = []
        Self.collect(
            nodes,
            level: 0,
            selected: selected,
            showOpenInCollapsed: showOpenInCollapsed,
            insideCollapsed: false,
            into: &rows
        )
        return rows
    }

    private static func collect(
        _ nodes: [Node],
        level: Int,
        selected: NodeID?,
        showOpenInCollapsed: Bool,
        insideCollapsed: Bool,
        into rows: inout [Row]
    ) {
        for node in nodes {
            switch node {
                case .entry(let entry):
                    if !insideCollapsed || (showOpenInCollapsed && entry.isOpen) || entry.id == selected {
                        rows.append(Row(id: entry.id, level: level, isFolder: false))
                    }
                case .folder(let folder):
                    if !insideCollapsed {
                        rows.append(Row(id: folder.id, level: level, isFolder: true))
                    }
                    let nextLevel = insideCollapsed ? level : level + 1
                    collect(
                        folder.children,
                        level: nextLevel,
                        selected: selected,
                        showOpenInCollapsed: showOpenInCollapsed,
                        insideCollapsed: insideCollapsed || folder.isCollapsed,
                        into: &rows
                    )
            }
        }
    }
}
