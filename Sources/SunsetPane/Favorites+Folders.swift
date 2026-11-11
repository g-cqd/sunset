public import Foundation

extension Favorites {
    /// A new, empty folder in `parent` (the top for nil) at `index`, or at the end. Nil when the name is blank, when `parent` is not a folder, or when it
    /// is as deep as folders go.
    @discardableResult
    public mutating func addFolder(named name: String, in parent: NodeID? = nil, at index: Int? = nil) -> NodeID? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, canHoldFolder(parent) else { return nil }
        let folder = Folder(name: name)
        return insert([.folder(folder)], into: parent, at: index) ? folder.id : nil
    }

    /// Puts nodes in a new folder where the first of them is, in the order they have in the tree. Nil, and nothing changed, when none of them is there or
    /// when a folder cannot be made at that depth.
    @discardableResult
    public mutating func group(_ ids: [NodeID], named name: String) -> NodeID? {
        let members = topmost(ids)
        guard let first = members.first, let location = location(of: first) else { return nil }
        guard let folder = addFolder(named: name, in: location.parent, at: location.index) else { return nil }
        move(members, into: folder, at: 0)
        return folder
    }

    /// Removes a folder and leaves what it holds in its place.
    public mutating func ungroup(_ id: NodeID) {
        guard let location = location(of: id), case .folder(let folder) = take(id) else { return }
        insert(folder.children, into: location.parent, at: location.index)
    }

    /// Shows or hides what a folder holds; kept with the session.
    public mutating func setCollapsed(_ collapsed: Bool, for id: NodeID) {
        updateFolder(id) { $0.isCollapsed = collapsed }
    }

    /// Names a folder or an entry. A blank name leaves a folder's name as it is, and gives an entry its content's title back.
    public mutating func rename(_ id: NodeID, to name: String?) {
        let name = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let given = name?.isEmpty == false ? name : nil
        update(id) { node in
            switch node {
                case .folder(var folder):
                    guard let given else { return }
                    folder.name = given
                    node = .folder(folder)
                case .entry(var entry):
                    entry.title = given
                    node = .entry(entry)
            }
        }
    }

    /// Gives a folder or an entry an icon; nil gives the default one back.
    public mutating func setIcon(_ icon: PaneIcon?, for id: NodeID) {
        update(id) { node in
            switch node {
                case .folder(var folder):
                    folder.icon = icon
                    node = .folder(folder)
                case .entry(var entry):
                    entry.icon = icon
                    node = .entry(entry)
            }
        }
    }

    /// Removes a node for good, with what it holds; returns the panes that were live in it.
    @discardableResult
    public mutating func remove(_ id: NodeID) -> [PaneID] {
        guard let node = take(id) else { return [] }
        return Self.livePanes(in: [node])
    }

    /// Whether a folder can be made in `parent`.
    private func canHoldFolder(_ parent: NodeID?) -> Bool {
        guard let parent else { return true }
        guard folder(parent) != nil, let level = location(of: parent)?.level else { return false }
        return level + 2 <= Self.maximumDepth
    }
}
