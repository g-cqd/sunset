import Foundation
package import SunsetPane

/// What a Space is named, what comes to it from another Space, what its tabs are found by, and the session.
extension SpaceModel {
    // MARK: What names it, and what comes to it

    package func rename(to name: String) {
        space.name = name
    }
    package func setIcon(_ icon: PaneIcon?) {
        space.icon = icon
    }
    package func setTint(_ tint: IconColor?) {
        space.tint = tint
    }
    package func setProfile(_ id: Profile.ID?) {
        space.profile = id
    }

    /// What a content of this Space's tabs asks is asked here: the Space knows the window that draws it.
    package func wire(_ content: any PaneContent, as pane: PaneID) {
        content.onExit = { [weak self] in self?.ended(pane) }
        content.onFocusRequest = { [weak self] in self?.focusRequested(pane) }
    }

    /// Takes tabs that run in another Space, after its own: still running, live in no window until one shows them.
    package func adopt(
        _ items: [Workspace.Item],
        contents moved: [PaneID: any PaneContent],
        pending waiting: [PaneID: PaneDescriptor]
    ) {
        guard !items.isEmpty else { return }
        let old = tabs.items
        for item in items { tabs.insert(item, at: tabs.count) }
        tabs = tabs.withoutSelection
        for (pane, content) in moved {
            contents[pane] = content
            wire(content, as: pane)
        }
        pending.merge(waiting) { first, _ in first }
        for viewer in currentViewers { viewer.tabsChanged(from: old) }
        syncStates()
    }

    /// Gives everything its tabs are, still running: the Space is deleted into another.
    package func giveAll() -> (
        items: [Workspace.Item], contents: [PaneID: any PaneContent], pending: [PaneID: PaneDescriptor]
    ) {
        let given = (tabs.items, contents, pending)
        tabs = Workspace()
        contents = [:]
        pending = [:]
        live = [:]
        stopped = nil
        return given
    }

    /// What a tab is searched by: the name it was given, and for each pane its title, its second line and what else its
    /// content says it is found by.
    package func fields(of item: Workspace.Item) -> [String] {
        let own = [item.customTitle ?? ""]
        let parts = item.panes.flatMap { pane -> [String] in
            // Not loaded, it is found by what it would start from.
            guard let content = contents[pane] else { return pending[pane]?.searchTerms ?? [] }
            return [content.title, content.detail ?? ""] + content.searchTerms
        }
        return (own + parts).filter { !$0.isEmpty }
    }

    // MARK: Session

    /// The Space as the session keeps it: without what is private (a tab of only private panes goes).
    package func saved() -> SavedSpace {
        var kept = tabs
        var descriptors = pending
        for (pane, content) in contents {
            if content.isPrivate { kept.close(pane: pane) } else { descriptors[pane] = content.descriptor }
        }
        var saved = SavedSpace(
            space: space,
            favorites: ownsFavorites ? favorites.saved() : SavedFavorites(),
            tabs: kept,
            contents: descriptors
        )
        saved.stopped = stopped
        return saved
    }

    /// Whether the session keeps the tab: one with a pane that is not private.
    package func keeps(_ item: Workspace.Item) -> Bool {
        item.panes.contains { contents[$0]?.isPrivate != true }
    }

    /// Takes a saved Space, before any window shows it: what names it, its Favorites, and (when `reopening`) its tabs,
    /// whose contents are made by the first window. With `reopening` off no entry comes back open and no tab comes back.
    package func restore(_ saved: SavedSpace, reopening: Bool = true) {
        space = saved.space
        guard reopening, tabs.isEmpty else { return }
        tabs = saved.tabs
        pending = saved.contents
        stopped = saved.stopped
    }
}
