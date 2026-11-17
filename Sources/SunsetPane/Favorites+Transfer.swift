extension Favorites {
    /// Takes the entry `id` out whole, as it is (its name, icon, command, home, and its live tab when it is open), to be
    /// put among other kept entries (the Favorites and the Pinned grid). Nil for a folder, and for an id that is not there.
    public mutating func takeEntry(_ id: NodeID) -> Entry? {
        guard entry(id) != nil, case .entry(let entry)? = take(id) else { return nil }
        return entry
    }

    /// Puts an entry in as it is, in `parent` (the top for nil) at `index` (the end for nil). False when `parent` is
    /// not a folder.
    @discardableResult
    public mutating func insert(_ entry: Entry, in parent: NodeID? = nil, at index: Int? = nil) -> Bool {
        insert([.entry(entry)], into: parent, at: index)
    }
}
