public import Foundation

extension Workspace {
    /// Gives the keyboard to a pane, selecting its tab. A pane that is not there changes nothing.
    public mutating func focus(pane: PaneID) {
        guard let index = items.firstIndex(where: { $0.layout.contains(pane) }) else { return }
        items[index].focused = pane
        show(items[index].id)
    }

    /// The next pane of the selected tab, the first after the last.
    public mutating func focusNext() {
        guard let item = selectedItem, let next = item.layout.pane(after: item.focused) else { return }
        focus(pane: next)
    }

    /// The previous pane of the selected tab, the last before the first.
    public mutating func focusPrevious() {
        guard let item = selectedItem, let previous = item.layout.pane(before: item.focused) else { return }
        focus(pane: previous)
    }

    /// A new pane on `edge` of `target`, in the tab that holds `target`, focused; nil when `target` is not in any tab.
    @discardableResult
    public mutating func addPane(beside target: PaneID, edge: PaneEdge) -> PaneID? {
        guard let index = items.firstIndex(where: { $0.layout.contains(target) }) else { return nil }
        let pane = PaneID()
        items[index].layout = items[index].layout.inserting(.pane(pane), beside: target, edge: edge)
        focus(pane: pane)
        return pane
    }

    /// Drops a whole tab on `edge` of the pane `target`: its panes join the tab that holds `target` (which is selected, with the keyboard on the dropped
    /// tab's focused pane) and the dropped tab is gone. Nothing happens for a tab dropped on itself, or for an unknown tab or pane.
    public mutating func drop(item id: ItemID, onto target: PaneID, edge: PaneEdge) {
        guard let from = items.firstIndex(where: { $0.id == id }),
            let into = items.firstIndex(where: { $0.layout.contains(target) }),
            from != into
        else { return }
        let dropped = items[from]
        items[into].layout = items[into].layout.inserting(dropped.layout, beside: target, edge: edge)
        items.remove(at: from)
        focus(pane: dropped.focused)
    }

    /// Moves one pane to `edge` of `target`, in the tab that holds `target`: the pane leaves its own tab (which is gone when it was the only pane) and takes
    /// the keyboard. In the same tab it rearranges the layout.
    public mutating func movePane(_ pane: PaneID, beside target: PaneID, edge: PaneEdge) {
        guard pane != target,
            let from = items.firstIndex(where: { $0.layout.contains(pane) }),
            let into = items.firstIndex(where: { $0.layout.contains(target) })
        else { return }
        if from == into {
            items[into].layout = items[into].layout.inserting(.pane(pane), beside: target, edge: edge)
        } else {
            let into = items[into].id
            leave(pane, from: from)
            guard let index = items.firstIndex(where: { $0.id == into }) else { return }
            items[index].layout = items[index].layout.inserting(.pane(pane), beside: target, edge: edge)
        }
        focus(pane: pane)
    }

    /// Closes one pane. Its space goes to its sibling and the keyboard to a pane that is left; the tab goes with its only pane.
    public mutating func close(pane: PaneID) {
        guard let index = items.firstIndex(where: { $0.layout.contains(pane) }) else { return }
        leave(pane, from: index)
    }

    /// Takes a pane out of a split into a tab of its own, right after that tab, selected. A pane that is alone in its tab stays where it is.
    public mutating func detach(pane: PaneID) {
        guard let index = items.firstIndex(where: { $0.layout.contains(pane) }), items[index].isSplit else { return }
        leave(pane, from: index)
        let tab = Item(layout: .pane(pane), focused: pane)
        items.insert(tab, at: index + 1)
        show(tab.id)
    }

    /// Sets how the split at `path` divides its space, in the tab `id`.
    public mutating func setRatio(_ ratio: Double, at path: [SplitBranch], in id: ItemID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].layout = items[index].layout.settingRatio(ratio, at: path)
    }

    /// Names the tab `item` instead of what its content says; `nil`, or a name with nothing but spaces, gives the content's title back (`n41`).
    public mutating func setTitle(_ title: String?, for item: ItemID) {
        guard let index = items.firstIndex(where: { $0.id == item }) else { return }
        let name = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].customTitle = name?.isEmpty == false ? name : nil
    }

    /// Gives the tab `item` an icon of the user's instead of its content's; `nil` gives the content's back (`n41`).
    public mutating func setIcon(_ icon: PaneIcon?, for item: ItemID) {
        guard let index = items.firstIndex(where: { $0.id == item }) else { return }
        items[index].customIcon = icon
    }

    /// Removes `pane` from the tab at `index`; the tab itself goes when it was the only pane.
    private mutating func leave(_ pane: PaneID, from index: Int) {
        if !items[index].remove(pane) { close(item: items[index].id) }
    }

    /// Applies a sidebar tab-row drop (`TabDropAction`): reorders a tab (or detaches a pane into its own tab) before or after `target`, or splits `target`'s
    /// focused pane on `edge` with the dragged tab or pane.
    public mutating func applyTabDrop(_ payload: PaneDragPayload, onto target: ItemID, action: TabDropAction) {
        switch (payload, action) {
            case (.item(let id), .moveBefore), (.item(let id), .moveAfter):
                guard id != target, let from = items.firstIndex(where: { $0.id == id }),
                    let into = items.firstIndex(where: { $0.id == target })
                else { return }
                let desired = action == .moveBefore ? into : into + 1
                let destination = from < desired ? desired - 1 : desired
                move(item: id, to: destination)
            case (.item(let id), .split(let edge)):
                guard id != target, let targetItem = items.first(where: { $0.id == target }) else { return }
                drop(item: id, onto: targetItem.focused, edge: edge)
            case (.pane(let pane), .split(let edge)):
                guard let targetItem = items.first(where: { $0.id == target }) else { return }
                movePane(pane, beside: targetItem.focused, edge: edge)
            case (.pane(let pane), .moveBefore), (.pane(let pane), .moveAfter):
                guard let source = item(containing: pane) else { return }
                let id: ItemID
                if source.isSplit {
                    detach(pane: pane)
                    guard let detached = item(containing: pane)?.id else { return }
                    id = detached
                } else {
                    id = source.id
                }
                applyTabDrop(.item(id), onto: target, action: action)
        }
    }
}
