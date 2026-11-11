package import Observation
package import SunsetPane

/// The Favorites of the app (`Favorites`) and the content of the panes of its open entries: one for every window (R3, R4). An open entry can be selected
/// in several windows, and is live (drawn, typed into) in one of them: the last that claimed it; the others show its last picture (R4, S-d). Its
/// content is made the first time it is shown, by the window that shows it.
@MainActor @Observable
package final class FavoritesModel {
    package private(set) var favorites = Favorites()
    /// The content of the live panes of open entries, made when an entry is first shown.
    package private(set) var contents: [PaneID: any PaneContent] = [:]
    /// What brings back the content of a live pane that has none yet (an entry that was open when the session was written).
    @ObservationIgnored private var pending: [PaneID: PaneDescriptor] = [:]
    /// The windows that can show entries, to tell the others when one takes an entry or when an entry goes.
    @ObservationIgnored private var viewers: [Weak] = []
    /// The window each open entry is live in.
    private var live: [Favorites.NodeID: Weak] = [:]
    /// Something changed that the session file holds.
    @ObservationIgnored package var onChange: () -> Void = {}

    package init() {}

    private struct Weak {
        weak var tabs: TabsModel?
    }

    package var isEmpty: Bool { favorites.isEmpty }
    /// Whether an entry is open: something of the user's would run with no window if the app stayed.
    package var hasOpenEntry: Bool { favorites.entries.contains(where: \.isOpen) }

    // MARK: Session

    /// Takes the Favorites of the session file. The entries that were open stay open when `reopening`; otherwise every entry is kept and none is open.
    package func restore(_ saved: SavedFavorites, reopening: Bool) {
        favorites = saved.favorites
        pending = saved.contents
        guard !reopening else { return }
        favorites.unloadAll()
        pending = [:]
    }

    /// The Favorites as they are, for the session file.
    package func saved() -> SavedFavorites {
        var descriptors = pending
        for (pane, content) in contents { descriptors[pane] = content.descriptor }
        return SavedFavorites(favorites: favorites, contents: descriptors)
    }

    // MARK: Windows

    func register(_ tabs: TabsModel) {
        viewers.removeAll { $0.tabs == nil || $0.tabs === tabs }
        viewers.append(Weak(tabs: tabs))
    }

    /// The entry is live in `tabs` now (the content is one view): the window that had it shows its last picture.
    func claim(_ id: Favorites.NodeID, by tabs: TabsModel) {
        let previous = live[id]?.tabs
        live[id] = Weak(tabs: tabs)
        if let previous, previous !== tabs { previous.syncStates() }
    }

    /// Whether the entry is live in `tabs`. An entry live nowhere (its window went) is live in no window until one takes it: two windows never
    /// draw the same content.
    func isLive(_ id: Favorites.NodeID, in tabs: TabsModel) -> Bool { live[id]?.tabs === tabs }

    /// `tabs` no longer shows the entry: when it was live there, it goes live in another window that shows it, if there is one.
    func unclaim(_ id: Favorites.NodeID, by tabs: TabsModel) {
        guard live[id]?.tabs === tabs else { return }
        live[id] = nil
        let next = viewers.lazy.compactMap(\.tabs).first { $0 !== tabs && $0.workspace.selectedEntry == id }
        next?.showEntry(id)
    }

    /// The entry stopped or went: every window that showed it shows its own tab again.
    private func released(_ id: Favorites.NodeID) {
        live[id] = nil
        for viewer in viewers where viewer.tabs?.workspace.selectedEntry == id { viewer.tabs?.leaveEntry() }
    }

    // MARK: Editing

    func edit(_ change: (inout Favorites) -> Void) {
        let before = favorites
        change(&favorites)
        if favorites != before { onChange() }
    }

    /// Keeps a tab of a window, with its content, as an entry that is open.
    func keep(
        _ item: Workspace.Item,
        contents moved: [PaneID: any PaneContent],
        in parent: Favorites.NodeID? = nil,
        at index: Int? = nil
    ) -> Favorites.NodeID? {
        var id: Favorites.NodeID?
        edit { id = $0.keep(item, contents: moved.mapValues(\.descriptor), in: parent, at: index) }
        for (pane, content) in moved { contents[pane] = content }
        return id
    }

    /// Opens an entry, making the content of its panes that have none with `make`; returns its live tab.
    func open(_ id: Favorites.NodeID, make: (PaneDescriptor?) -> any PaneContent) -> Workspace.Item? {
        var item: Workspace.Item?
        let home = favorites.entry(id)?.home
        edit { item = $0.open(id) }
        guard let item else { return nil }
        for pane in item.panes where contents[pane] == nil {
            let content = make(pending.removeValue(forKey: pane) ?? home?.contents[pane])
            content.onExit = { [weak self] in self?.paneEnded(pane) }
            contents[pane] = content
        }
        return item
    }

    /// Stops an entry and keeps it.
    package func unload(_ id: Favorites.NodeID) {
        var gone: [PaneID] = []
        edit { gone = $0.unload(id) }
        stop(gone)
        released(id)
    }

    /// Removes an entry for good.
    package func delete(_ id: Favorites.NodeID) {
        var gone: [PaneID] = []
        edit { gone = $0.remove(id) }
        stop(gone)
        released(id)
    }

    /// Takes an entry out of the Favorites, as a tab with its content (open), or with what to make it from (not open).
    func release(_ id: Favorites.NodeID) -> (
        item: Workspace.Item, live: [PaneID: any PaneContent], home: [PaneID: PaneDescriptor]
    )? {
        var result: (item: Workspace.Item, home: [PaneID: PaneDescriptor]?)?
        released(id)
        edit { result = $0.release(id) }
        guard let result else { return nil }
        var live: [PaneID: any PaneContent] = [:]
        for pane in result.item.panes { live[pane] = contents.removeValue(forKey: pane) }
        return (result.item, live, result.home ?? [:])
    }

    /// Makes the place an entry starts from what it is now (`Set Home to Current`).
    package func setHomeToCurrent(_ id: Favorites.NodeID) {
        guard let open = favorites.entry(id)?.open else { return }
        let descriptors = open.panes.reduce(into: [PaneID: PaneDescriptor]()) { $0[$1] = contents[$1]?.descriptor }
        edit { $0.setHome(Favorites.Home(layout: open.layout, focused: open.focused, contents: descriptors), for: id) }
    }

    func addPane(beside target: PaneID, edge: PaneEdge, content: any PaneContent) -> Bool {
        var pane: PaneID?
        edit { pane = $0.addPane(beside: target, edge: edge) }
        guard let pane else { return false }
        content.onExit = { [weak self] in self?.paneEnded(pane) }
        contents[pane] = content
        return true
    }

    /// Closes one pane of an open entry, as asked; the entry is unloaded, and kept, with its last pane.
    func close(pane: PaneID) {
        guard let id = favorites.entry(containing: pane)?.id else { return }
        var unloaded = false
        edit { unloaded = $0.close(pane: pane) }
        stop([pane])
        if unloaded { released(id) }
    }

    /// A program in an entry's pane ended by itself.
    private func paneEnded(_ pane: PaneID) { close(pane: pane) }

    private func stop(_ panes: [PaneID]) {
        for pane in panes {
            contents.removeValue(forKey: pane)?.stop()
            pending[pane] = nil
        }
    }
}
