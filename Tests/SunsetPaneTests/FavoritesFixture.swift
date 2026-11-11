import Foundation
import Testing

@testable import SunsetPane

/// What the Favorites suites build their trees from.
enum FavoritesFixture {
    /// A tab of `panes` panes side by side, the first focused.
    static func item(panes count: Int = 1) -> Workspace.Item {
        let first = PaneID()
        var layout = SplitLayout.pane(first)
        var last = first
        for _ in 1 ..< max(count, 1) {
            let next = PaneID()
            layout = layout.inserting(.pane(next), beside: last, edge: .right)
            last = next
        }
        return Workspace.Item(layout: layout, focused: first)
    }

    /// What a kept terminal starts from: one pane, a shell in `directory`.
    static func home(_ directory: String = "/tmp") -> Favorites.Home {
        let pane = PaneID()
        return Favorites.Home(layout: .pane(pane), focused: pane, contents: [pane: .terminal(directory: directory)])
    }

    /// `depth` folders one inside the other, named "1", "2", …; their ids from the outermost in.
    static func chain(_ depth: Int, in favorites: inout Favorites) -> [Favorites.NodeID] {
        var ids: [Favorites.NodeID] = []
        for level in 1 ... depth {
            guard let id = favorites.addFolder(named: "\(level)", in: ids.last) else { break }
            ids.append(id)
        }
        return ids
    }

    /// The value, or the test stops here. (`#require` cannot take a call that changes a variable.)
    static func need<Value>(_ value: Value?, sourceLocation: SourceLocation = #_sourceLocation) throws -> Value {
        try #require(value, sourceLocation: sourceLocation)
    }

    /// The names of the tree, nested: folders as `name[children]`, entries by their title (or "-").
    static func shape(_ nodes: [Favorites.Node]) -> String {
        nodes.map { node in
            switch node {
                case .folder(let folder): "\(folder.name)[\(shape(folder.children))]"
                case .entry(let entry): entry.title ?? "-"
            }
        }
        .joined(separator: " ")
    }
}
