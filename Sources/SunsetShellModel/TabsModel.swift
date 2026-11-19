package import Foundation
package import Observation
package import SunsetPane
package import SunsetRuntime

/// One window's view of a Space (`SpaceModel`; ADR-0045): the Space's tabs with this window's selection (`workspace`), and
/// what is only the window's (the command bar, a rename in progress, the pointer). The tabs and the content of each pane
/// (`PaneContent`: a terminal, a page) are the Space's: they run while the presentation changes or a window closes. A pane
/// not shown is told it has no focus and is not visible (it neither blinks nor draws); of those shown, the focused blinks.
@MainActor @Observable
package final class TabsModel {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    @ObservationIgnored package var runtime = Runtime.live

    /// The Space this window shows.
    package internal(set) var space: SpaceModel
    /// The tab this window selected among the Space's, and the kept entry it shows instead (`workspace`).
    package var selectedID: Workspace.ItemID? {
        didSet {
            remember(selectedID, was: oldValue)
        }
    }
    /// The tabs this window showed, the last last (n4): closing the shown one goes back to the one before it.
    @ObservationIgnored package var shownBefore: [Workspace.ItemID] = []
    package var selectedEntry: Favorites.NodeID?
    /// Makes a pane's content: the default kind for nil, else what the descriptor says; a placeholder until the app says
    /// how, then the Space's tabs with none (stopped with its last window, or read from the session) are given theirs.
    @ObservationIgnored package var makeContent: (PaneDescriptor?) -> any PaneContent = {
        UnknownContent($0 ?? PaneDescriptor(kind: ""))
    }
    {
        didSet {
            canMake = true
            revive()
        }
    }
    @ObservationIgnored package var canMake = false
    /// The scopes of the app that are on (roadmap 0033): nothing of one that is off is made or listed here.
    package var scopes = Scopes() {
        didSet {
            if scopes != oldValue { scopesChanged() }
        }
    }
    /// The Pinned grid this window shows (the app's); nil for a window that has none (a private one).
    package var pinned: FavoritesModel? {
        didSet {
            pinned?.register(self)
        }
    }
    /// The Spaces this window can change to (the app's); nil for one whose Space is its own. Observed: drawn before set.
    package weak var spaces: SpacesModel?
    /// Where the sidebar's field is, in the window, while it shows one: the command bar opens there (roadmap 0035 G).
    package var sidebarField: CGRect?
    /// The window is kept awake, and until when (roadmap 0035 E).
    package internal(set) var windowAwake: KeepAwake?
    /// What this window had selected in each Space it left: shown again when it comes back.
    @ObservationIgnored package var selections: [Space.ID: SavedView] = [:]
    /// What a Space's editor holds while it is open in this window; the Space being deleted, asked about first.
    package var spaceDraft: SpaceDraft?
    package var deletingSpace: Space.ID?
    /// The window closes with its Space's last tab; closing the shown tab shows the one before it (`tabs.*`, n4).
    @ObservationIgnored package var closesWithLastTab = false
    @ObservationIgnored package var closeGoesBack = true
    /// The swipe between Spaces under way on this window's sidebar, and the list's slide from one Space to another.
    @ObservationIgnored package var spaceSwipe = SpaceSwipe()
    package var slide = SpaceSlide()
    /// Runs a slide: the change, animated, then what follows it (a test runs it by hand).
    @ObservationIgnored package var runSlide = SpaceSlide.atOnce
    /// Makes a change with no animation at all (the views give theirs: a transaction that disables them).
    @ObservationIgnored package var withoutAnimation: @MainActor (() -> Void) -> Void = { change in
        change()
    }
    /// What a content asks of a window (links to open, the font zoom) is asked of this one from now on: it draws it.
    @ObservationIgnored package var wireContent: (any PaneContent) -> Void = { _ in }
    /// The window chose what it shows (its Space, a first tab), once; the last tab was closed: the window goes.
    @ObservationIgnored package var started = false
    @ObservationIgnored package var onEmpty: () -> Void = {}
    /// The tabs changed (added, closed, moved, split, selected): the session is to be saved.
    @ObservationIgnored package var onChange: () -> Void = {}
    /// What a drag in this window carries, from its start (`beginDrag`) until it is dropped.
    @ObservationIgnored package var dragged: PaneDragPayload? {
        didSet {
            draggedChanged()
        }
    }
    /// Where what is dragged could go, while a drag is under way: what the views outline (`DragTargets`).
    package internal(set) var dragTargets: DragTargets?
    /// Whether a mouse button is down: a drag let go where nothing takes it ends when none is (watched by `dragWatch`).
    /// Whether a mouse button is down: the app gives the system's (`NSEvent.pressedMouseButtons`); none by default.
    @ObservationIgnored package var mouseIsDown: @MainActor () -> Bool = { false }
    @ObservationIgnored package var dragWatch: Task<Void, Never>?
    /// The command bar when open; what was gone to or searched from it, latest last (Up in its empty field).
    package var bar: CommandBar?
    package var barRecall: [String] = []
    /// This window's temporary font size change (⌘+, ⌘−, ⌘0).
    package var fontZoom = FontZoom()
    /// The pane whose sub-tab is currently under the pointer in a split container (`SidebarGroupRow`), so its terminal card can highlight its stroke.
    package var hoveredPane: PaneID?
    /// The tab row currently under the pointer in the sidebar or tab bar, so an unselected tab can show a screen preview (`n36`).
    package var hoveredItem: Workspace.ItemID? {
        didSet {
            // Pointed at: what it would show gets ready (note n1).
            guard let hoveredItem, hoveredItem != oldValue, let item = previewItem(hoveredItem) else { return }
            for pane in item.panes { content(pane)?.prepare() }
        }
    }
    /// Where that row, the pane area and the sidebar are, in the window: the preview goes in the area, beside the sidebar
    /// (n47, roadmap 0047 B).
    package var hoveredRowFrame: CGRect?
    package var paneAreaFrame: CGRect?
    package var sidebarFrame: CGRect?
    /// The folder of the Favorites under the pointer: its card lists its tabs (the owner's note n77).
    package var hoveredFolder: Favorites.NodeID?
    /// The tab being renamed (`RenameTabAlert`) and the kept entry whose command is edited (`CommandSheet`).
    package var renaming: Workspace.ItemID?
    package var editingCommand: Favorites.NodeID?
    /// The choice of kind for a new tab is open (Shift-Cmd-T); the panel opposite the tabs is shown (Cmd-Y, web step e);
    /// which section each sidebar is on (roadmap 0031).
    package var choosingKind = false
    package var showsHistory = false
    package var sections = SidebarSections()
    @ObservationIgnored package let shelf = DocumentShelf()
    /// A private window (web step h): the group its pages share by default, and whether they do (the window's selector).
    package var privateGroup: UUID?
    package var privateShares = true
    package var isPrivateWindow: Bool {
        privateGroup != nil
    }
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
    @ObservationIgnored package var expiryTask: Task<Void, Never>?

    /// The Favorites of the Space.
    package var favorites: FavoritesModel {
        space.favorites
    }

    /// A window on `space`, with nothing selected.
    package init(space: SpaceModel) {
        self.space = space
        space.register(self)
        space.favorites.register(self)
    }

    /// A window that only looks at `space` (`preview(of:)`): not among its viewers.
    package init(previewing space: SpaceModel, selected: Workspace.ItemID?, pinned: FavoritesModel?) {
        self.space = space
        self.selectedID = selected
        self.pinned = pinned
    }

    /// A window with tabs of its own: a Space no other window shows, that ends with it.
    package convenience init(favorites: FavoritesModel = FavoritesModel()) {
        self.init(space: SpaceModel(favorites: favorites))
    }

    package var selectedContent: (any PaneContent)? {
        shownPane.flatMap(content)
    }

    // MARK: Adding

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

    package func register(_ model: any PaneContent, as pane: PaneID) {
        contents[pane] = model
        onChange()
        // What it asks is asked of the Space, which knows the window that draws the pane now: this one may be gone by then.
        // (A terminal that is not shown cannot be clicked: a request from one is the window handing the keyboard back to
        // a view that is going away, and must not select its tab again: `SpaceModel.focusRequested`.)
        space.wire(model, as: pane)
        syncStates()
    }
}
