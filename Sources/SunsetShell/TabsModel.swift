package import Foundation
package import Observation
package import SunsetPane

/// One window's view of a Space (`SpaceModel`; ADR-0045): the Space's tabs with this window's selection (`workspace`), and
/// what is only the window's (the command bar, a rename in progress, the pointer). The tabs and the content of each pane
/// (`PaneContent`: a terminal, a page) are the Space's, not a view's and not a window's: the presentation can change, and
/// a window can close, while they run. A pane that is not shown is told it has no focus and is not visible, so that it
/// neither blinks nor draws; of the shown panes only the focused one blinks.
@MainActor @Observable
package final class TabsModel {
    /// The Space this window shows.
    package internal(set) var space: SpaceModel
    /// The tab this window has selected among the Space's, and the kept entry it shows instead (`workspace`).
    var selectedID: Workspace.ItemID?
    var selectedEntry: Favorites.NodeID?
    /// Makes the content of a pane: the app's default kind for nil, else what the descriptor says. Until the app says how, a
    /// pane is a placeholder. Once it can, the tabs of the Space that have no content (stopped with its last window, or read
    /// from the session) are given theirs.
    @ObservationIgnored package var makeContent: (PaneDescriptor?) -> any PaneContent = {
        UnknownContent($0 ?? PaneDescriptor(kind: ""))
    }
    {
        didSet {
            canMake = true
            revive()
        }
    }
    @ObservationIgnored var canMake = false
    /// The Spaces this window can change to (the app's); nil for a window whose Space is its own. Observed: what shows the
    /// Spaces is drawn before a window is among them.
    package weak var spaces: SpacesModel?
    /// What this window had selected in each Space it left: shown again when it comes back.
    @ObservationIgnored var selections: [Space.ID: SavedView] = [:]
    /// What the editor of a Space holds while it is open in this window (a new Space's, or one's that exists), and the
    /// Space being deleted, which is asked about first.
    package var spaceDraft: SpaceDraft?
    package var deletingSpace: Space.ID?
    /// Whether the window closes when the last tab of its Space does (`tabs.closeWindowWithLastTab`); off, it stays, on an
    /// empty Space (the owner, 2026-11-17).
    @ObservationIgnored package var closesWithLastTab = false
    /// The swipe between Spaces under way on this window's sidebar, and the side the list last came in from.
    package var spaceSwipe = SpaceSwipe()
    package var spaceCameFromNext = true
    /// What a content asks of a window (links to open, the font zoom) is asked of this one from now on: it draws it.
    @ObservationIgnored package var wireContent: (any PaneContent) -> Void = { _ in }
    /// The window chose what it shows (its Space, a first tab): done once, though its content can be built again.
    @ObservationIgnored package var started = false
    /// The last tab was closed: the window goes.
    @ObservationIgnored package var onEmpty: () -> Void = {}
    /// The tabs changed (added, closed, moved, split, selected): the session is to be saved.
    @ObservationIgnored package var onChange: () -> Void = {}
    /// What a sidebar or bar drag in this window carries, from its start until it is dropped (set when the drag begins; see `beginDrag`).
    @ObservationIgnored package var dragged: PaneDragPayload?
    /// The command bar, when it is open: searching the tabs, or (after the selected tab was dropped on its own content) choosing the tab to split with.
    package var bar: CommandBar?
    /// What was gone to or searched from the bar in this window, latest last; Up in its empty field brings them back (kept for the session).
    package var barRecall: [String] = []
    /// This window's temporary font size change (⌘+, ⌘−, ⌘0).
    package var fontZoom = FontZoom()
    /// The pane whose sub-tab is currently under the pointer in a split container (`SidebarGroupRow`), so its terminal card can highlight its stroke.
    package var hoveredPane: PaneID?
    /// The tab row currently under the pointer in the sidebar or tab bar, so an unselected tab can show a screen preview (`n36`).
    package var hoveredItem: Workspace.ItemID?
    /// Where that row is, in the window (global coordinates): the preview is placed beside it (n47).
    package var hoveredRowFrame: CGRect?
    /// The tab being renamed, while its dialog is open (`RenameTabAlert`).
    package var renaming: Workspace.ItemID?
    /// The kept entry whose command is being edited, while its sheet is open (`CommandSheet`).
    package var editingCommand: Favorites.NodeID?
    /// The choice of kind for a new tab is open (Shift-Cmd-T).
    package var choosingKind = false
    /// The panel on the side opposite the tabs is shown (Cmd-Y, web step e), and which section each sidebar is on (roadmap 0031).
    package var showsHistory = false
    package var sections = SidebarSections()
    @ObservationIgnored package let shelf = DocumentShelf()
    /// A private window (web step h): the group its pages share by default, and whether they do (the window's selector).
    package var privateGroup: UUID?
    package var privateShares = true
    package var isPrivateWindow: Bool { privateGroup != nil }
    package var clearingHistory = false
    /// The row whose name is being edited in place, and the row whose icon popover is open.
    package var renamingRow: RowTarget?
    package var iconRow: RowTarget?
    /// The rows selected together (Cmd-click, Shift-click), in the sidebar's order, and the row a Shift-click counts from (R3 step d).
    package var marked: [RowTarget] = []
    package var markAnchor: RowTarget?
    /// Two-step confirmation before closing a tab that has a command running (`n28`).
    package var closeConfirmation = CloseConfirmation()
    /// What is asked before unsaved edits close (`UnsavedSheet`); nil when nothing is.
    package var unsavedQuestion: UnsavedQuestion?
    /// Whether closing a busy tab requires a second click or ⌘W (`tabs.confirmClose`).
    package var confirmClose = true
    @ObservationIgnored private var expiryTask: Task<Void, Never>?

    /// The Favorites of the Space.
    package var favorites: FavoritesModel { space.favorites }

    /// A window on `space`, with nothing selected.
    package init(space: SpaceModel) {
        self.space = space
        space.register(self)
        space.favorites.register(self)
    }

    /// A window with tabs of its own: a Space no other window shows, that ends with it.
    package convenience init(favorites: FavoritesModel = FavoritesModel()) {
        self.init(space: SpaceModel(favorites: favorites))
    }

    package var selectedContent: (any PaneContent)? { shownPane.flatMap(content) }

    // MARK: Adding

    /// A new tab, selected, after the current one: a terminal, or what `descriptor` says.
    package func newTab(_ descriptor: PaneDescriptor? = nil) {
        let entry = workspace.selectedEntry
        register(makeContent(descriptor), as: workspace.add().pane)
        if let entry { left(entry) }
    }

    /// A new terminal beside the focused pane, in the same tab, with the keyboard; nothing when there is no focused pane.
    package func newSplit(_ edge: PaneEdge) {
        if shownEntry != nil, let target = shownPane {
            if favorites.addPane(beside: target, edge: edge, content: makeContent(nil)) { syncStates() }
            return
        }
        guard let target = workspace.selectedPane, let pane = workspace.addPane(beside: target, edge: edge) else {
            return
        }
        register(makeContent(nil), as: pane)
    }

    /// Takes content that already runs (moved from another window when the presentation changed): a tab like any other, selected.
    package func adopt(_ content: any PaneContent) {
        let entry = workspace.selectedEntry
        register(content, as: workspace.add().pane)
        if let entry { left(entry) }
    }

    // MARK: Session

    /// The window as it is, for the session file: the tabs and what brings the content of each pane back.
    /// The window as the session keeps it: without its private panes (a tab of only private panes goes).
    package func savedWindow() -> SavedWindow {
        var kept = workspace
        for (pane, content) in contents where content.isPrivate { kept.close(pane: pane) }
        return SavedWindow(workspace: kept, contents: contents.filter { !$0.value.isPrivate }.mapValues(\.descriptor))
    }

    /// Fills an empty window with a saved one: the same tabs and splits, and in each pane the content its descriptor says (a new terminal in its
    /// directory, a note with its text). The terminals of tabs that are not shown start when their tab is first shown.
    package func restore(_ saved: SavedWindow) {
        guard workspace.isEmpty else { return }
        // A saved window may have no tab of its own when it showed a kept entry; with neither, it starts with a new tab.
        guard !saved.workspace.isEmpty || saved.workspace.selectedEntry != nil else { return newTab() }
        workspace = saved.workspace
        for pane in workspace.allPanes {
            register(makeContent(saved.contents[pane] ?? .terminal(directory: nil)), as: pane)
        }
        // The entry it showed is made now (an entry's content is made by the window that first shows it).
        if let entry = workspace.selectedEntry {
            workspace.select(entry: nil)
            select(entry: entry)
        }
    }

    func register(_ model: any PaneContent, as pane: PaneID) {
        contents[pane] = model
        onChange()
        // What it asks is asked of the Space, which knows the window that draws the pane now: this one may be gone by then.
        // (A terminal that is not shown cannot be clicked: a request from one is the window handing the keyboard back to
        // a view that is going away, and must not select its tab again: `SpaceModel.focusRequested`.)
        space.wire(model, as: pane)
        syncStates()
    }

    // MARK: Removing

    /// Takes a pane out without stopping its program: the terminal goes to another window. The window is not told it is empty (the caller decides).
    package func detach(pane: PaneID) -> (any PaneContent)? {
        guard let model = contents[pane] else { return nil }
        workspace.close(pane: pane)
        contents[pane] = nil
        syncStates()
        onChange()
        return model
    }

    /// Closes a pane immediately (used when its program exits on its own).
    package func close(pane: PaneID) {
        guard let model = contents[pane] else { return }
        if let item = workspace.item(containing: pane)?.id, isCloseArmed(item) { closeConfirmation.disarm() }
        if hoveredPane == pane { hoveredPane = nil }
        workspace.close(pane: pane)
        contents[pane] = nil
        model.stop()
        finishClosing()
    }

    /// Whether `item` is currently armed for close confirmation (tinted red).
    package func isCloseArmed(_ item: Workspace.ItemID) -> Bool {
        closeConfirmation.isArmed(item: item, now: .now)
    }

    func confirmed(_ target: CloseConfirmation.Target, isBusy: Bool) -> Bool {
        let allowed = closeConfirmation.shouldClose(target, isBusy: isBusy, enabled: confirmClose, now: .now)
        if !allowed, let deadline = closeConfirmation.expiration {
            expiryTask?.cancel()
            expiryTask = Task { [weak self] in
                try? await Task.sleep(until: deadline, clock: .continuous)
                guard !Task.isCancelled else { return }
                self?.closeConfirmation.expire(at: .now)
            }
        }
        return allowed
    }

    /// The window closed: it no longer shows its Space. While another window does, nothing stops; the last window of a Space
    /// that keeps its tabs stops them and they stay; any other Space ends with its window.
    package func windowClosed(at date: Date = Date()) {
        space.leave(self, at: date)
        spaces?.windowClosed(at: date)
    }

    func stop(_ panes: [PaneID]) {
        for pane in panes {
            if hoveredPane == pane { hoveredPane = nil }
            contents[pane]?.stop()
            contents[pane] = nil
        }
    }

    /// The window goes with its last tab, unless it shows a kept entry or there are Favorites to show (it stays, with a hint: R3).
    func finishClosing() {
        onChange()
        if workspace.isEmpty, workspace.selectedEntry == nil, favorites.isEmpty { emptied() } else { syncStates() }
    }

    /// Tells every content whether it is shown and whether it has the keyboard: the Space's tabs', each by the window it is
    /// live in, and the panes of the kept entry this window shows.
    func syncStates() {
        space.syncStates()
        guard workspace.selectedEntry != nil, showsLive else { return }
        let focused = shownPane
        for pane in shownEntry?.open?.panes ?? [] {
            favorites.contents[pane]?.setState(focused: pane == focused, visible: true)
        }
    }
}
