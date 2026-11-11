public import Foundation

/// `{"nodes": [node]}`, a node being `{"kind": "folder", "id", "name", "icon"?, "collapsed", "children": [node]}` or
/// `{"kind": "entry", "id", "title"?, "icon"?, "home": {"layout", "focused", "contents"}, "open"?: {"id", "layout", "focused"}}`.
///
/// Reading never refuses the whole tree. A node that cannot be read is left out; so is one whose id was seen before, and whatever is past
/// `maximumNodes`; folders deeper than `maximumDepth` dissolve; an entry that claims a pane another one has live is read as not open.
extension Favorites: Codable {
    private enum Key: String, CodingKey { case nodes }

    /// What reading has seen so far.
    private struct Repair {
        var seen = Set<NodeID>()
        var live = Set<PaneID>()
        var left = Favorites.maximumNodes

        /// Counts a node; false when its id was seen or the bound is reached.
        mutating func admit(_ id: NodeID) -> Bool {
            guard left > 0, seen.insert(id).inserted else { return false }
            left -= 1
            return true
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let read = try container.decode([Node.Lossy].self, forKey: .nodes).compactMap(\.value)
        self.init()
        var repair = Repair()
        nodes = Self.repaired(read, level: 0, &repair)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(nodes, forKey: .nodes)
    }

    private static func repaired(_ nodes: [Node], level: Int, _ repair: inout Repair) -> [Node] {
        var result: [Node] = []
        for node in nodes {
            switch node {
                case .entry(var entry):
                    guard repair.admit(entry.id) else { continue }
                    if let panes = entry.open?.panes {
                        if repair.live.isDisjoint(with: panes) {
                            repair.live.formUnion(panes)
                        } else {
                            entry.open = nil
                        }
                    }
                    result.append(.entry(entry))
                case .folder(var folder):
                    guard level < maximumDepth else {
                        result += repaired(folder.children, level: level, &repair)
                        continue
                    }
                    guard repair.admit(folder.id) else { continue }
                    folder.children = repaired(folder.children, level: level + 1, &repair)
                    result.append(.folder(folder))
            }
        }
        return result
    }
}
