package import Foundation
package import Observation
package import SunsetPane

/// A Space while the app runs (R4; ADR-0045): its tabs, the content of their panes, and its Favorites. A window is a view of
/// one (`TabsModel`): every window on a Space lists the same tabs, each with its own selection, and a tab is drawn and typed
/// into in one window at most, the one that last clicked it; the others show its last picture.
///
/// Like `FavoritesModel` for kept entries, this is where what several windows share lives. A Space that keeps its tabs
/// (`keepsTabs`: the app's) stops them and keeps them when its last window closes, and starts them again, where they were,
/// in the next window; one that does not (a private window's, a window that is one tab) ends them with its window.
@MainActor @Observable
package final class SpaceModel {
    package private(set) var space: Space
    /// The tabs in order, with no selection: each window has its own.
    package private(set) var tabs = Workspace()
    package internal(set) var contents: [PaneID: any PaneContent] = [:]
    package let favorites: FavoritesModel
    /// Whether its tabs stay, stopped, when its last window closes (the app's Space, unless `tabs.closeWithLastWindow`).
    package var keepsTabs: Bool
    /// Its tabs were stopped with its last window and wait for the next; since when.
    package var isStopped: Bool { stopped != nil }
    package private(set) var stopped: Date?
    /// What brings back the content of a pane that has none: read from the session, or stopped with the last window.
    @ObservationIgnored private var pending: [PaneID: PaneDescriptor] = [:]
    @ObservationIgnored private var viewers: [Weak] = []
    /// The window each tab is live in.
    private var live: [Workspace.ItemID: Weak] = [:]

    private struct Weak {
        weak var tabs: TabsModel?
    }

    package init(space: Space = Space(), favorites: FavoritesModel = FavoritesModel(), keepsTabs: Bool = false) {
        self.space = space
        self.favorites = favorites
        self.keepsTabs = keepsTabs
    }

    package var viewerCount: Int { viewers.count { $0.tabs != nil } }
    private func others(than viewer: TabsModel?) -> [TabsModel] { viewers.compactMap(\.tabs).filter { $0 !== viewer } }

    // MARK: Windows

    func register(_ viewer: TabsModel) {
        viewers.removeAll { $0.tabs == nil || $0.tabs === viewer }
        viewers.append(Weak(tabs: viewer))
    }

    /// `viewer`'s window closed. What it drew goes to a window that still shows it; with no window left, the tabs stop and
    /// stay (a Space that keeps them) or end.
    func leave(_ viewer: TabsModel, at date: Date = Date()) {
        viewers.removeAll { $0.tabs == nil || $0.tabs === viewer }
        for (id, owner) in live where owner.tabs === viewer { handOver(id) }
        if viewers.isEmpty {
            if keepsTabs { stopKeeping(at: date) } else { closeAll() }
        }
        syncStates()
    }

    /// Ends every tab: what runs is stopped and nothing is kept.
    private func closeAll() {
        for content in contents.values {
            content.onExit = {}
            content.stop()
        }
        tabs = Workspace()
        contents = [:]
        pending = [:]
        live = [:]
        stopped = nil
    }

    /// Closes the tabs that were stopped with the last window once they have waited `interval` seconds (0 is never).
    /// - Returns: whether they were closed.
    @discardableResult
    package func closeStopped(after interval: TimeInterval, now: Date = Date()) -> Bool {
        guard interval > 0, let stopped, viewerCount == 0, now.timeIntervalSince(stopped) >= interval else {
            return false
        }
        closeAll()
        return true
    }

    /// The tab is live in `viewer` now, when no window has it or when `force` (a click): the window that had it shows its
    /// last picture. What its panes ask for is asked of `viewer` from now on.
    func claim(_ id: Workspace.ItemID, by viewer: TabsModel, force: Bool) {
        let previous = live[id]?.tabs
        guard previous !== viewer, previous == nil || force else { return }
        live[id] = Weak(tabs: viewer)
        for pane in tabs.items.first(where: { $0.id == id })?.panes ?? [] {
            if let content = contents[pane] { viewer.wireContent(content) }
        }
    }

    func isLive(_ id: Workspace.ItemID, in viewer: TabsModel) -> Bool { live[id]?.tabs === viewer }
    /// No window draws the tab.
    func isFree(_ id: Workspace.ItemID) -> Bool { live[id]?.tabs == nil }

    /// `viewer`, its only window, leaves for another Space and takes the tabs along: they are given, still running.
    func give(to viewer: TabsModel) -> (items: [Workspace.Item], contents: [PaneID: any PaneContent]) {
        guard others(than: viewer).isEmpty else {
            leave(viewer)
            return ([], [:])
        }
        let given = (tabs.items, contents)
        viewers = []
        tabs = Workspace()
        contents = [:]
        live = [:]
        return given
    }

    /// `viewer` no longer shows the tab: when it was live there, it goes live in another window that shows it, if any.
    func unclaim(_ id: Workspace.ItemID, by viewer: TabsModel) {
        guard live[id]?.tabs === viewer else { return }
        handOver(id, from: viewer)
    }

    private func handOver(_ id: Workspace.ItemID, from viewer: TabsModel? = nil) {
        live[id] = nil
        if let next = others(than: viewer).first(where: { $0.shownTab == id }) { claim(id, by: next, force: true) }
    }

    // MARK: The tabs

    /// The tabs as `viewer` changed them. The other windows keep a selection that is still there, and a tab that went is
    /// live nowhere.
    func set(_ new: Workspace, by viewer: TabsModel) {
        let old = tabs.items
        guard new.items != old else { return }
        tabs = new.withoutSelection
        let present = Set(tabs.items.map(\.id))
        for id in live.keys where !present.contains(id) { live[id] = nil }
        for other in others(than: viewer) { other.tabsChanged(from: old) }
    }

    /// A program in a pane ended by itself: its pane closes, in the window that draws it or in any.
    func ended(_ pane: PaneID) {
        // What was stopped, or went to another Space, is not this Space's to close.
        guard contents[pane] != nil else { return }
        let owner = tabs.item(containing: pane).flatMap { live[$0.id]?.tabs } ?? viewers.lazy.compactMap(\.tabs).first
        if let owner {
            owner.close(pane: pane)
        } else {
            tabs.close(pane: pane)
            contents.removeValue(forKey: pane)?.stop()
            pending[pane] = nil
        }
    }

    /// A pane asks for the keyboard: given by the window that draws it, when it shows it.
    func focusRequested(_ pane: PaneID) {
        guard let item = tabs.item(containing: pane), let owner = live[item.id]?.tabs,
            owner.shownItem?.panes.contains(pane) == true
        else { return }
        owner.focus(pane)
    }

    /// Tells every content of the Space's tabs whether it is shown and whether it has the keyboard: shown in the window its
    /// tab is live in, while that window has the tab selected.
    func syncStates() {
        for item in tabs.items {
            let shown = live[item.id]?.tabs?.shownTab == item.id
            for pane in item.panes { contents[pane]?.setState(focused: shown && pane == item.focused, visible: shown) }
        }
    }

    // MARK: Stopping and starting

    /// The last window went: what runs is stopped, and the tabs stay with what brings each pane back. What is private
    /// keeps nothing: its tabs go.
    private func stopKeeping(at date: Date) {
        for (pane, content) in contents {
            if content.isPrivate { tabs.close(pane: pane) } else { pending[pane] = content.descriptor }
            // Its end is not a pane closing: the tab stays.
            content.onExit = {}
            content.stop()
        }
        contents = [:]
        live = [:]
        stopped = tabs.isEmpty ? nil : date
    }

    /// What brings back the content of `pane`, which has none; taken, since the content is about to be made.
    func takePending(_ pane: PaneID) -> PaneDescriptor? {
        stopped = nil
        return pending.removeValue(forKey: pane)
    }

    // MARK: Session

    /// The Space as the session keeps it: without what is private (a tab of only private panes goes).
    package func saved() -> SavedSpace {
        var kept = tabs
        var descriptors = pending
        for (pane, content) in contents {
            if content.isPrivate { kept.close(pane: pane) } else { descriptors[pane] = content.descriptor }
        }
        var saved = SavedSpace(space: space, favorites: favorites.saved(), tabs: kept, contents: descriptors)
        saved.stopped = stopped
        return saved
    }

    /// Whether the session keeps the tab: one with a pane that is not private.
    func keeps(_ item: Workspace.Item) -> Bool { item.panes.contains { contents[$0]?.isPrivate != true } }

    /// Takes a saved Space, before any window shows it: what names it, its Favorites, and (when `reopening`) its tabs,
    /// whose contents are made by the first window. With `reopening` off no entry comes back open and no tab comes back.
    package func restore(_ saved: SavedSpace, reopening: Bool = true) {
        space = saved.space
        favorites.restore(saved.favorites, reopening: reopening)
        guard reopening, tabs.isEmpty else { return }
        tabs = saved.tabs
        pending = saved.contents
        stopped = saved.stopped
    }
}
