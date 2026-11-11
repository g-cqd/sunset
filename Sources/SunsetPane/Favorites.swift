public import Foundation

/// What is kept in the sidebar whether it is open or not (R3, R4): a tree of folders and kept entries. There is one for the app, shown in every window;
/// the tabs made on the fly stay each window's (`Workspace`).
///
/// A folder nests others to `maximumDepth` levels and lives until it is removed, empty or not. An entry remembers what it starts from (its `home`) and,
/// while it is open, holds its live tab: unloading it stops what runs and keeps the entry. Like `Workspace` it is a value that knows nothing of what a
/// pane shows; the operations that stop something return the panes that went.
public struct Favorites: Sendable, Equatable {
    public typealias NodeID = UUID

    /// How deep folders nest: a folder at the top is at level one.
    public static let maximumDepth = 4
    /// The most nodes read from a file; the rest is left out.
    public static let maximumNodes = 4096

    public internal(set) var nodes: [Node] = []

    public init() {}

    public var isEmpty: Bool { nodes.isEmpty }

    /// Every node, folders included.
    public var count: Int {
        var total = 0
        walk { _, _ in total += 1 }
        return total
    }

    /// Every entry, in the order of the tree.
    public var entries: [Entry] {
        var result: [Entry] = []
        walk { node, _ in if case .entry(let entry) = node { result.append(entry) } }
        return result
    }

    /// The panes of the entries that are open, in the order of the tree.
    public var livePanes: [PaneID] { entries.flatMap { $0.open?.panes ?? [] } }

    public func node(_ id: NodeID) -> Node? {
        var found: Node?
        walk { node, _ in if node.id == id { found = node } }
        return found
    }

    public func entry(_ id: NodeID) -> Entry? {
        if case .entry(let entry) = node(id) { entry } else { nil }
    }

    public func folder(_ id: NodeID) -> Folder? {
        if case .folder(let folder) = node(id) { folder } else { nil }
    }

    /// The open entry that holds `pane`.
    public func entry(containing pane: PaneID) -> Entry? {
        entries.first { $0.open?.layout.contains(pane) == true }
    }

    /// Where a node is: the folder that holds it (nil at the top), its place there, and how many folders are above it.
    public func location(of id: NodeID) -> Location? {
        var found: Location?
        walk { node, location in if node.id == id { found = location } }
        return found
    }

    /// Visits every node, a folder before what it holds.
    func walk(_ visit: (Node, Location) -> Void) { Self.walk(nodes, parent: nil, level: 0, visit) }

    private static func walk(_ nodes: [Node], parent: NodeID?, level: Int, _ visit: (Node, Location) -> Void) {
        for (index, node) in nodes.enumerated() {
            visit(node, Location(parent: parent, index: index, level: level))
            if case .folder(let folder) = node { walk(folder.children, parent: folder.id, level: level + 1, visit) }
        }
    }
}
