import Foundation

extension Favorites {
    /// The same folders and entries with ids of their own and nothing open: what a new Space starts with (the owner,
    /// 2026-11-17). An entry's home keeps its layout, with panes of its own (a pane is in one place), and what each starts
    /// from; its name, icon and command are kept, with the command's seal (which is of the command, not of the entry).
    public func copied() -> Favorites {
        var copy = Favorites()
        copy.nodes = nodes.map(Self.copied)
        return copy
    }

    private static func copied(_ node: Node) -> Node {
        switch node {
            case .folder(let folder):
                return .folder(
                    Folder(
                        name: folder.name,
                        icon: folder.icon,
                        isCollapsed: folder.isCollapsed,
                        children: folder.children.map(copied)
                    )
                )
            case .entry(let entry):
                var panes: [PaneID: PaneID] = [:]
                for pane in entry.home.layout.panes { panes[pane] = PaneID() }
                var contents: [PaneID: PaneDescriptor] = [:]
                for (pane, descriptor) in entry.home.contents { contents[panes[pane] ?? pane] = descriptor }
                let home = Home(
                    layout: entry.home.layout.replacing(panes),
                    focused: panes[entry.home.focused] ?? entry.home.focused,
                    contents: contents
                )
                var made = Entry(title: entry.title, icon: entry.icon, home: home)
                made.command = entry.command
                made.commandSeal = entry.commandSeal
                return .entry(made)
        }
    }
}

extension Favorites {
    /// Takes everything `other` holds, as it is (open entries stay open), after what is here: a Space deleted into this one.
    public mutating func absorb(_ other: Favorites) { insert(other.nodes, into: nil) }
}
