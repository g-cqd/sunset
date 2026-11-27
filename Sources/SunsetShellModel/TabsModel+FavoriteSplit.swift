import Foundation
package import SunsetPane

/// Splitting on a kept entry (a row of the Favorites or a tile of the Pinned grid): on its top or bottom quarter (or outer
/// quarters on a tile) what is dragged goes before or after it; on its middle half it splits in place inside the kept entry,
/// never releasing the Favorite or Pinned entry into Today's tabs.
extension TabsModel {
    /// Whether what is dragged can be dropped on the kept entry `target` with `action`.
    package func canDrop(onEntry target: Favorites.NodeID, action: TabDropAction) -> Bool {
        adoptDrag()
        switch action {
            case .moveBefore, .moveAfter:
                if isPinned(target) {
                    guard case .entry(target)? = dragged else { return canPinDragged }
                    return false
                }
                return canDrop(onEntry: target)
            case .split:
                let model = keeper(of: target)
                guard model.favorites.entry(target) != nil, draggedSelection == nil else { return false }
                switch dragged {
                    case .item, .document:
                        return true
                    case .pane(let pane):
                        return workspace.item(containing: pane) != nil
                            || (keeper(ofPane: pane)?.favorites.entry(containing: pane)?.id != target
                                && (keeper(ofPane: pane)?.favorites.entry(containing: pane)?.open?.panes.count ?? 0) > 1)
                    case .entry(let id):
                        guard id != target else { return false }
                        let origin = Self.dragOrigin ?? self
                        return origin.keeper(of: id).favorites.entry(id) != nil
                    case nil:
                        return false
                }
        }
    }

    /// Drops what is dragged on the kept entry `target` with `action`.
    @discardableResult
    package func dropDragged(onEntry target: Favorites.NodeID, action: TabDropAction) -> Bool {
        switch action {
            case .moveBefore, .moveAfter:
                let after = action == .moveAfter
                if isPinned(target) {
                    guard let index = pinnedEntries.firstIndex(where: { $0.id == target }) else { return false }
                    return dropDragged(in: .pinned(at: index + (after ? 1 : 0)))
                }
                return dropDragged(onEntry: target, after: after)
            case .split(let edge):
                guard canDrop(onEntry: target, action: action) else { return false }
                bringDraggedHere()
                guard let extracted = takeDraggedForEntrySplit(excluding: target) else { return false }
                dragged = nil
                let model = keeper(of: target)
                select(entry: target)
                guard let open = model.favorites.entry(target)?.open else { return false }
                guard
                    model.insertLayout(
                        extracted.layout,
                        focused: extracted.focused,
                        beside: open.focused,
                        edge: edge,
                        contents: extracted.contents
                    )
                else { return false }
                showEntry(target)
                return true
        }
    }

    /// Takes the dragged tab, pane, document or kept entry out of its source as a ready-to-insert layout and live contents
    /// without touching Today's tabs when splitting into a kept entry.
    func takeDraggedForEntrySplit(excluding target: Favorites.NodeID? = nil) -> (
        layout: SplitLayout, focused: PaneID, contents: [PaneID: any PaneContent]
    )? {
        guard let drag = dragged else { return nil }
        switch drag {
            case .document(let id):
                let pane = PaneID()
                let content = makeContent(.document(stored: id))
                wireContent(content)
                return (.pane(pane), pane, [pane: content])
            case .item(let id):
                guard let taken = workspace.take(item: id) else { return nil }
                var moved: [PaneID: any PaneContent] = [:]
                for pane in taken.panes {
                    let content =
                        contents.removeValue(forKey: pane)
                        ?? makeContent(space.pending.removeValue(forKey: pane) ?? .terminal(directory: nil))
                    wireContent(content)
                    moved[pane] = content
                }
                return (taken.layout, taken.focused, moved)
            case .pane(let pane):
                if workspace.item(containing: pane) != nil {
                    let content =
                        detach(pane: pane)
                        ?? makeContent(space.pending.removeValue(forKey: pane) ?? .terminal(directory: nil))
                    wireContent(content)
                    return (.pane(pane), pane, [pane: content])
                }
                guard let source = keeper(ofPane: pane),
                    source.favorites.entry(containing: pane)?.id != target,
                    let content = source.separate(pane: pane)
                else { return nil }
                wireContent(content)
                return (.pane(pane), pane, [pane: content])
            case .entry(let id):
                guard id != target else { return nil }
                let source = keeper(of: id)
                unloadIfForeignProfile(id, in: source)
                guard let released = source.release(id) else { return nil }
                var moved: [PaneID: any PaneContent] = [:]
                for pane in released.item.panes {
                    let content =
                        released.live[pane] ?? makeContent(released.home[pane] ?? .terminal(directory: nil))
                    wireContent(content)
                    moved[pane] = content
                }
                return (released.item.layout, released.item.focused, moved)
        }
    }
}
