package import SunsetPane

/// The name and icon a person gives a tab, over what its program says (`n41`).
extension TabsModel {
    /// Opens the rename dialog for `item` (`RenameTabAlert`).
    package func beginRename(item: Workspace.ItemID) { renaming = item }

    package func rename(item: Workspace.ItemID, to name: String, icon: PaneIcon?) {
        change {
            $0.setTitle(name, for: item)
            $0.setIcon(icon, for: item)
        }
    }

    /// The tab's name and icon as the rows show them: nil where the tab has none of its own, or an icon the system cannot draw.
    package func custom(for item: Workspace.Item) -> (name: String?, icon: PaneIcon?) {
        (item.customTitle, item.customIcon.flatMap { PaneIconView.canShow($0) ? $0 : nil })
    }
}

/// Names and icons edited in place (R3 step c), for a tab, an entry or a folder.
extension TabsModel {
    /// The name a row shows, for its in-place field: the tab's or entry's own name, else its content's title; a folder's name.
    package func name(of row: RowTarget) -> String {
        switch row {
            case .tab(let id):
                guard let item = workspace.items.first(where: { $0.id == id }) else { return "" }
                return item.customTitle ?? content(item.focused)?.title ?? ""
            case .node(let id):
                switch favorites.favorites.node(id) {
                    case .folder(let folder): return folder.name
                    case .entry(let entry):
                        return entry.title ?? entry.open.flatMap { content($0.focused)?.title } ?? ""
                    case nil: return ""
                }
        }
    }

    /// The icon a row was given, if any.
    package func icon(of row: RowTarget) -> PaneIcon? {
        switch row {
            case .tab(let id): workspace.items.first { $0.id == id }?.customIcon
            case .node(let id):
                switch favorites.favorites.node(id) {
                    case .folder(let folder): folder.icon
                    case .entry(let entry): entry.icon
                    case nil: nil
                }
        }
    }

    /// Names a row (blank gives a tab or entry its content's title back; a folder keeps its name).
    package func rename(_ row: RowTarget, to name: String) {
        switch row {
            case .tab(let id): change { $0.setTitle(name, for: id) }
            case .node(let id): favorites.edit { $0.rename(id, to: name) }
        }
        if renamingRow == row { renamingRow = nil }
    }

    /// Gives a row an icon (nil gives its own back).
    package func setIcon(_ icon: PaneIcon?, for row: RowTarget) {
        switch row {
            case .tab(let id): change { $0.setIcon(icon, for: id) }
            case .node(let id): favorites.edit { $0.setIcon(icon, for: id) }
        }
    }
}
