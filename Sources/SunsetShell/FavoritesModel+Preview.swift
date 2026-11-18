package import SunsetPane

/// A folder's preview (the owner's note n77): the tabs it holds, nested ones too, as a list, not a tree.
extension FavoritesModel {
    /// An entry was shown: it is the most recently used.
    func noteUsed(_ id: Favorites.NodeID) {
        used[id] = (used.values.max() ?? 0) + 1
    }

    /// The entries of a folder and of the folders in it, in the order its preview lists them (the owner, 2026-11-17): the
    /// open ones first, the most recently used first; then the others, in the folder's order.
    /// - Parameter folder: a folder of these Favorites.
    /// - Returns: its entries; none for a folder that is not there.
    package func previewEntries(in folder: Favorites.NodeID) -> [Favorites.Entry] {
        guard let found = favorites.folder(folder) else { return [] }
        var all: [Favorites.Entry] = []
        var pending = Array(found.children.reversed())
        while let node = pending.popLast() {
            switch node {
                case .entry(let entry): all.append(entry)
                case .folder(let inner): pending += inner.children.reversed()
            }
        }
        let open = all.filter(\.isOpen).enumerated()
            .sorted { (used[$0.element.id] ?? 0, -$0.offset) > (used[$1.element.id] ?? 0, -$1.offset) }
            .map(\.element)
        return open + all.filter { !$0.isOpen }
    }
}
