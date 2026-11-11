public import Foundation

extension Favorites {
    /// Keeps a tab: it becomes an entry that is open, and that starts from what the tab is now (its layout, and `contents` for its panes). The tab's own
    /// name and icon become the entry's. Nil when `parent` is not a folder.
    @discardableResult
    public mutating func keep(
        _ item: Workspace.Item,
        contents: [PaneID: PaneDescriptor],
        in parent: NodeID? = nil,
        at index: Int? = nil
    ) -> NodeID? {
        let home = Home(layout: item.layout, focused: item.focused, contents: contents)
        let live = Workspace.Item(id: item.id, layout: item.layout, focused: item.focused)
        let entry = Entry(title: item.customTitle, icon: item.customIcon, home: home, open: live)
        return insert([.entry(entry)], into: parent, at: index) ? entry.id : nil
    }

    /// Adds an entry that is not open. Nil when `home` does not hold together or `parent` is not a folder.
    @discardableResult
    public mutating func addEntry(
        home: Home,
        title: String? = nil,
        icon: PaneIcon? = nil,
        in parent: NodeID? = nil,
        at index: Int? = nil
    ) -> NodeID? {
        guard home.holdsTogether else { return nil }
        let name = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = Entry(title: name?.isEmpty == false ? name : nil, icon: icon, home: home)
        return insert([.entry(entry)], into: parent, at: index) ? entry.id : nil
    }

    /// Opens an entry from its home and returns its live tab; the one it has when it is open already. The caller makes the content of its panes.
    @discardableResult
    public mutating func open(_ id: NodeID) -> Workspace.Item? {
        guard let entry = entry(id) else { return nil }
        if let open = entry.open { return open }
        let item = Workspace.Item(layout: entry.home.layout, focused: entry.home.focused)
        updateEntry(id) { $0.open = item }
        return item
    }

    /// Stops an entry and keeps it; returns the panes that went.
    @discardableResult
    public mutating func unload(_ id: NodeID) -> [PaneID] {
        guard let panes = entry(id)?.open?.panes else { return [] }
        updateEntry(id) { $0.open = nil }
        return panes
    }

    /// Stops every entry; returns the panes that went.
    @discardableResult
    public mutating func unloadAll() -> [PaneID] {
        entries.filter(\.isOpen).flatMap { unload($0.id) }
    }

    /// Takes an entry out of the Favorites to be an ordinary tab again, with its name and icon. Open, its live tab is returned and `home` is nil; not
    /// open, the tab is its home and `home` says what to make its panes from.
    public mutating func release(_ id: NodeID) -> (item: Workspace.Item, home: [PaneID: PaneDescriptor]?)? {
        guard let entry = entry(id) else { return nil }
        _ = take(id)
        if let open = entry.open {
            let item = Workspace.Item(
                id: open.id,
                layout: open.layout,
                focused: open.focused,
                customTitle: entry.title,
                customIcon: entry.icon
            )
            return (item, nil)
        }
        let item = Workspace.Item(
            layout: entry.home.layout,
            focused: entry.home.focused,
            customTitle: entry.title,
            customIcon: entry.icon
        )
        return (item, entry.home.contents)
    }
}

extension Favorites {
    /// What an entry starts from from now on (`Set Home to Current`). A home that does not hold together changes nothing.
    public mutating func setHome(_ home: Home, for id: NodeID) {
        guard home.holdsTogether else { return }
        updateEntry(id) { $0.home = home }
    }
}

extension Favorites {
    /// Gives a kept entry the command typed into its shell when it opens, with the check that says who wrote it; a blank command removes both.
    public mutating func setCommand(_ command: String?, seal: String?, for id: NodeID) {
        let text = command?.trimmingCharacters(in: .whitespacesAndNewlines)
        let given = text?.isEmpty == false ? text : nil
        updateEntry(id) { entry in
            entry.command = given
            entry.commandSeal = given == nil ? nil : seal
        }
    }
}
