package import Foundation
package import Observation
package import SunsetPane
import SunsetRuntime

/// A Space while the app runs: its tabs and the content of their panes. A window is a view of one (`TabsModel`): every
/// window on a Space lists the same tabs, each with its own selection, and a tab is drawn and typed into in one window at
/// most, the one that last clicked it; the others show its last picture.
///
/// Like `FavoritesModel` for kept entries, this is where what several windows share lives. A Space that keeps its tabs
/// (`keepsTabs`: the app's) stops them and keeps them when its last window closes, and starts them again, where they were,
/// in the next window; one that does not (a private window's, a window that is one tab) ends them with its window.
@MainActor @Observable
package final class SpaceModel {
    package internal(set) var space: Space
    /// The tabs in order, with no selection: each window has its own.
    package internal(set) var tabs = Workspace()
    package internal(set) var contents: [PaneID: any PaneContent] = [:]
    /// The Favorites its windows show: its profile's, the same in every Space of the profile; its own for a Space that
    /// is not among the app's (a private window's, a window that is one tab).
    package internal(set) var favorites: FavoritesModel
    /// Its Favorites are its own, not its profile's (`spaces.favorites`): saved with it, asked about when it is
    /// deleted.
    package internal(set) var ownsFavorites = false
    /// Whether its tabs stay, stopped, when its last window closes (the app's Space, unless `tabs.closeWithLastWindow`).
    package var keepsTabs: Bool
    /// Its tabs were stopped with its last window and wait for the next; since when.
    package var isStopped: Bool {
        stopped != nil
    }
    package internal(set) var stopped: Date?
    /// Something in it asked for attention while no window showed it (S-e): its icon is marked until one does.
    package internal(set) var needsAttention = false
    /// What brings back the content of a pane that has none: read from the session, or stopped with the last window.
    @ObservationIgnored package var pending: [PaneID: PaneDescriptor] = [:]
    @ObservationIgnored private var viewers: [Weak] = []
    /// The window each tab is live in.
    package var live: [Workspace.ItemID: Weak] = [:]

    package struct Weak {
        package weak var tabs: TabsModel?
    }

    package init(space: Space = Space(), favorites: FavoritesModel = FavoritesModel(), keepsTabs: Bool = false) {
        self.space = space
        self.favorites = favorites
        self.keepsTabs = keepsTabs
    }

    package var viewerCount: Int {
        viewers.count { $0.tabs != nil }
    }
    /// The windows that show it.
    package var currentViewers: [TabsModel] {
        viewers.compactMap(\.tabs)
    }
    /// A window that shows it, if any.
    package var currentViewer: TabsModel? {
        currentViewers.first
    }
    /// It has a tab: deleting it asks first. (The Favorites are its profile's, and stay.)
    package var holdsSomething: Bool {
        !tabs.isEmpty || (ownsFavorites && !favorites.isEmpty)
    }
    /// The tab a window last went to: what a window that comes to this Space for the first time shows.
    package private(set) var lastShown: Workspace.ItemID?
    private func others(than viewer: TabsModel?) -> [TabsModel] {
        viewers.compactMap(\.tabs).filter { $0 !== viewer }
    }

    // MARK: Windows

    package func register(_ viewer: TabsModel) {
        viewers.removeAll { $0.tabs == nil || $0.tabs === viewer }
        viewers.append(Weak(tabs: viewer))
        needsAttention = false
    }

    /// Something in it asks for attention (a notification, S-e): marked when no window shows it.
    package func noteActivity() {
        if viewerCount == 0 { needsAttention = true }
    }

    /// `viewer`'s window closed. What it drew goes to a window that still shows it; with no window left, the tabs stop and
    /// stay (a Space that keeps them) or end.
    package func leave(_ viewer: TabsModel, at date: Date = Runtime.live.now()) {
        park(viewer)
        stopIfUnshown(at: date)
    }

    /// `viewer` changed to another Space: what it drew goes to a window that still shows it, or is hidden. Nothing
    /// stops: a Space left by changing runs on.
    package func park(_ viewer: TabsModel) {
        viewers.removeAll { $0.tabs == nil || $0.tabs === viewer }
        for (id, owner) in live where owner.tabs === viewer { handOver(id) }
        syncStates()
    }

    /// With no window on it: its tabs stop and stay (a Space that keeps them), or end. What a window closing does to its
    /// Space, and what the app's last window closing does to every Space.
    package func stopIfUnshown(at date: Date = Runtime.live.now()) {
        guard viewerCount == 0, !contents.isEmpty || !keepsTabs else { return }
        if keepsTabs { stopKeeping(at: date) } else { closeAll() }
    }

    /// Ends every tab: what runs is stopped and nothing is kept.
    package func closeAll() {
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
    package func closeStopped(after interval: TimeInterval, now: Date = Runtime.live.now()) -> Bool {
        guard interval > 0, let stopped, viewerCount == 0, now.timeIntervalSince(stopped) >= interval else {
            return false
        }
        closeAll()
        return true
    }

    /// The tab is live in `viewer` now, when no window has it or when `force` (a click): the window that had it shows its
    /// last picture. What its panes ask for is asked of `viewer` from now on.
    package func claim(_ id: Workspace.ItemID, by viewer: TabsModel, force: Bool) {
        let previous = live[id]?.tabs
        guard previous !== viewer, previous == nil || force else { return }
        live[id] = Weak(tabs: viewer)
        lastShown = id
        for pane in tabs.items.first(where: { $0.id == id })?.panes ?? [] {
            guard let content = contents[pane] else { continue }
            // The window it leaves shows its picture.
            if previous != nil { TabSwitchSignpost.interval("takePicture (claim)") { content.takePicture() } }
            viewer.wireContent(content)
        }
    }

    package func isLive(_ id: Workspace.ItemID, in viewer: TabsModel) -> Bool {
        live[id]?.tabs === viewer
    }
    /// No window draws the tab.
    package func isFree(_ id: Workspace.ItemID) -> Bool {
        live[id]?.tabs == nil
    }

    /// `viewer`, its only window, leaves for another Space and takes the tabs along: they are given, still running.
    package func give(to viewer: TabsModel) -> (items: [Workspace.Item], contents: [PaneID: any PaneContent]) {
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
    package func unclaim(_ id: Workspace.ItemID, by viewer: TabsModel) {
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
    package func set(_ new: Workspace, by viewer: TabsModel) {
        let old = tabs.items
        guard new.items != old else { return }
        tabs = new.withoutSelection
        let present = Set(tabs.items.map(\.id))
        for id in live.keys where !present.contains(id) { live[id] = nil }
        for other in others(than: viewer) { other.tabsChanged(from: old) }
    }

    /// A program in a pane ended by itself: its pane closes, in the window that draws it or in any.
    package func ended(_ pane: PaneID) {
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
    package func focusRequested(_ pane: PaneID) {
        guard let item = tabs.item(containing: pane), let owner = live[item.id]?.tabs,
            owner.shownItem?.panes.contains(pane) == true
        else { return }
        owner.focus(pane)
    }

    /// Tells every content of the Space's tabs whether it is shown and whether it has the keyboard: shown in the window its
    /// tab is live in, while that window has the tab selected.
    package func syncStates() {
        TabSwitchSignpost.interval("syncStates") {
            for item in tabs.items {
                let shown = live[item.id]?.tabs?.shownTab == item.id
                for pane in item.panes {
                    guard let content = contents[pane] else { continue }
                    TabSwitchSignpost.setState(kind: content.descriptor.kind, shown: shown) {
                        content.setState(focused: shown && pane == item.focused, visible: shown)
                    }
                }
            }
        }
    }
}
