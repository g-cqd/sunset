extension Favorites {
    /// The entry `id`, or every entry in the folder `id` and its folders, in the sidebar's order.
    public func entries(under id: NodeID) -> [Entry] {
        if let entry = entry(id) { return [entry] }
        guard let folder = folder(id) else { return [] }
        return Self.entries(in: folder.children)
    }

    private static func entries(in nodes: [Node]) -> [Entry] {
        nodes.flatMap { node in
            switch node {
                case .entry(let entry): [entry]
                case .folder(let folder): entries(in: folder.children)
            }
        }
    }
}
