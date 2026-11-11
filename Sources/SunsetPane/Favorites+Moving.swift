public import Foundation

extension Favorites {
    /// Moves nodes together into `parent` (the top for nil), in the order they have in the tree. `index` counts among what `parent` holds once the moved
    /// nodes are taken out, and is brought inside. A folder that would land deeper than the limit dissolves: what it holds takes its place (the owner's
    /// rule, "flattened to fit"). Nothing moves into an entry, an unknown node, or a folder into itself or what it holds.
    public mutating func move(_ ids: [NodeID], into parent: NodeID?, at index: Int) {
        let members = topmost(ids)
        guard !members.isEmpty else { return }
        if let parent {
            guard folder(parent) != nil else { return }
            let moved = members.compactMap { node($0) }
            guard !Self.contains(parent, in: moved) else { return }
        }
        let taken = members.compactMap { take($0) }
        insert(taken, into: parent, at: index)
    }

    /// Those of `ids` that are in the tree, in its order, without the ones that are inside another of them.
    func topmost(_ ids: [NodeID]) -> [NodeID] {
        let wanted = Set(ids)
        var result: [NodeID] = []
        Self.collect(wanted, in: nodes, into: &result)
        return result
    }

    private static func collect(_ wanted: Set<NodeID>, in nodes: [Node], into result: inout [NodeID]) {
        for node in nodes {
            if wanted.contains(node.id) {
                result.append(node.id)
            } else if case .folder(let folder) = node {
                collect(wanted, in: folder.children, into: &result)
            }
        }
    }
}
