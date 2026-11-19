extension Favorites {
    /// Takes from `other` what this does not already have, after its own: a folder of the same name is one folder, with
    /// the children of both; an entry that looks like one here (the same name, icon, command and what it starts from)
    /// is that entry, and of the two the open one is kept. What the Favorites of several Spaces become when they are
    /// the profile's (ADR-0055): a Space made from another had a copy of its Favorites.
    public mutating func merge(_ other: Favorites) {
        nodes = Self.merged(nodes, other.nodes)
    }

    private static func merged(_ mine: [Node], _ theirs: [Node]) -> [Node] {
        var result = mine
        for node in theirs {
            switch node {
                case .folder(let folder):
                    let same = result.firstIndex {
                        if case .folder(let one) = $0 { one.name == folder.name } else { false }
                    }
                    if let same, case .folder(var existing) = result[same] {
                        existing.children = merged(existing.children, folder.children)
                        result[same] = .folder(existing)
                    } else {
                        result.append(node)
                    }
                case .entry(let entry):
                    let same = result.firstIndex {
                        if case .entry(let one) = $0 { one.looks(like: entry) } else { false }
                    }
                    if let same, case .entry(let existing) = result[same] {
                        if !existing.isOpen, entry.isOpen { result[same] = node }
                    } else {
                        result.append(node)
                    }
            }
        }
        return result
    }
}
