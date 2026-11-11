import Foundation

/// The edits every operation is made of.
extension Favorites {
    /// Changes the node `id` where it is; false when it is not there.
    @discardableResult
    mutating func update(_ id: NodeID, _ change: (inout Node) -> Void) -> Bool {
        Self.update(id, in: &nodes, change)
    }

    @discardableResult
    mutating func updateEntry(_ id: NodeID, _ change: (inout Entry) -> Void) -> Bool {
        update(id) { node in
            guard case .entry(var entry) = node else { return }
            change(&entry)
            node = .entry(entry)
        }
    }

    @discardableResult
    mutating func updateFolder(_ id: NodeID, _ change: (inout Folder) -> Void) -> Bool {
        update(id) { node in
            guard case .folder(var folder) = node else { return }
            change(&folder)
            node = .folder(folder)
        }
    }

    /// Takes the node `id` out, with what it holds.
    mutating func take(_ id: NodeID) -> Node? { Self.take(id, from: &nodes) }

    /// Puts `new` among what `parent` holds (the top for nil) at `index`, brought inside, or at the end; folders that would be deeper than the limit
    /// dissolve. False when `parent` is not a folder.
    @discardableResult
    mutating func insert(_ new: [Node], into parent: NodeID?, at index: Int? = nil) -> Bool {
        guard let parent else {
            let fitted = Self.fitted(new, level: 0)
            nodes.insert(contentsOf: fitted, at: Self.place(index, in: nodes))
            return true
        }
        guard folder(parent) != nil, let level = location(of: parent)?.level else { return false }
        let fitted = Self.fitted(new, level: level + 1)
        return updateFolder(parent) { $0.children.insert(contentsOf: fitted, at: Self.place(index, in: $0.children)) }
    }

    /// Whether `id` is one of `nodes` or inside one of them.
    static func contains(_ id: NodeID, in nodes: [Node]) -> Bool {
        nodes.contains { node in
            if node.id == id { return true }
            if case .folder(let folder) = node { return contains(id, in: folder.children) }
            return false
        }
    }

    /// `nodes` as they fit `level` folders down: a folder that would be deeper than the limit is replaced by what it holds.
    static func fitted(_ nodes: [Node], level: Int) -> [Node] {
        nodes.flatMap { node -> [Node] in
            guard case .folder(var folder) = node else { return [node] }
            guard level < maximumDepth else { return fitted(folder.children, level: level) }
            folder.children = fitted(folder.children, level: level + 1)
            return [.folder(folder)]
        }
    }

    /// The live panes of the entries among `nodes`, at any depth.
    static func livePanes(in nodes: [Node]) -> [PaneID] {
        nodes.flatMap { node -> [PaneID] in
            switch node {
                case .entry(let entry): entry.open?.panes ?? []
                case .folder(let folder): livePanes(in: folder.children)
            }
        }
    }

    private static func place(_ index: Int?, in nodes: [Node]) -> Int {
        index.map { min(max($0, 0), nodes.count) } ?? nodes.count
    }

    private static func update(_ id: NodeID, in nodes: inout [Node], _ change: (inout Node) -> Void) -> Bool {
        for index in nodes.indices {
            if nodes[index].id == id {
                change(&nodes[index])
                return true
            }
            guard case .folder(var folder) = nodes[index], update(id, in: &folder.children, change) else { continue }
            nodes[index] = .folder(folder)
            return true
        }
        return false
    }

    private static func take(_ id: NodeID, from nodes: inout [Node]) -> Node? {
        if let index = nodes.firstIndex(where: { $0.id == id }) { return nodes.remove(at: index) }
        for index in nodes.indices {
            guard case .folder(var folder) = nodes[index], let taken = take(id, from: &folder.children) else {
                continue
            }
            nodes[index] = .folder(folder)
            return taken
        }
        return nil
    }
}
