public import Foundation

extension Workspace {
    /// A copy of the tab `id` right after it: the same layout of new panes, its name and icon; shown when `show`.
    /// - Returns: each pane of the tab and the pane of the copy in its place; empty when there is no such tab.
    @discardableResult
    public mutating func duplicate(_ id: ItemID, show: Bool) -> [PaneID: PaneID] {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return [:] }
        let item = items[index]
        let names = Dictionary(uniqueKeysWithValues: item.panes.map { ($0, PaneID()) })
        let copy = Item(
            layout: item.layout.renaming(names),
            focused: names[item.focused] ?? item.focused,
            customTitle: item.customTitle,
            customIcon: item.customIcon
        )
        items.insert(copy, at: index + 1)
        if show { self.show(copy.id) }
        return names
    }
}
