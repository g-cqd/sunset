import Foundation

/// Favorites built from elsewhere, a whole tree at once (another browser's bookmarks): one insertion, not one walk of
/// the tree per node.
extension Favorites {
    /// A new folder holding `children`; a blank name is no name, and the folder is left out where it is put.
    public static func newFolder(named name: String, children: [Node]) -> Node {
        .folder(Folder(name: name.trimmingCharacters(in: .whitespacesAndNewlines), children: children))
    }

    /// A new entry that is not open; nil when `home` does not hold together.
    public static func newEntry(home: Home, title: String?) -> Node? {
        guard home.holdsTogether else { return nil }
        let name = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        return .entry(Entry(title: name?.isEmpty == false ? name : nil, home: home))
    }

    /// Puts `new` at the end of the top, as `insert` does: a folder that would be deeper than the limit gives what it holds
    /// to the one above.
    public mutating func append(_ new: [Node]) {
        insert(new, into: nil)
    }
}
