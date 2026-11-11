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
