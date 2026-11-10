import Foundation
import Observation
import SunsetHost
import SunsetPane

/// The tabs of one window: their order, the selection and the split of each (`Workspace`), and the terminal of each pane. The programs belong to this store,
/// not to a view, so the presentation (built-in bar, or one tab per window with the sidebar listing them) can change while they run. A pane that is not
/// shown is told it has no focus and is not visible, so that it neither blinks nor draws; of the shown panes only the focused one blinks.
@MainActor @Observable
final class TabsModel {
    private(set) var workspace = Workspace()
    private(set) var models: [PaneID: TerminalModel] = [:]
    /// Makes and configures a terminal for a new pane (the scene knows the launch options and the configuration).
    @ObservationIgnored var makeModel: () -> TerminalModel = { TerminalModel() }
    /// The last tab was closed: the window goes.
    @ObservationIgnored var onEmpty: () -> Void = {}
    /// The tabs changed (added, closed, moved, split, selected): the session is to be saved.
    @ObservationIgnored var onChange: () -> Void = {}
    /// The directories a restored window had, for panes that have not started yet (a tab starts when it is first shown) and so cannot report their own.
    @ObservationIgnored private var savedDirectories: [PaneID: String] = [:]

    /// What a sidebar or bar drag in this window carries, from its start until it is dropped (set when the drag begins; see `beginDrag`).
    @ObservationIgnored var dragged: PaneDragPayload?
    /// The command bar, when it is open: searching the tabs, or (after the selected tab was dropped on its own content) choosing the tab to split with.
    var bar: CommandBar?
    /// This window's temporary font size change (⌘+, ⌘−, ⌘0).
    var fontZoom = FontZoom()
    /// The pane whose sub-tab is currently under the pointer in a split container (`SidebarGroupRow`), so its terminal card can highlight its stroke.
    var hoveredPane: PaneID?

    var selectedModel: TerminalModel? { workspace.selectedPane.flatMap { models[$0] } }
    var allModels: [TerminalModel] { workspace.allPanes.compactMap { models[$0] } }

    // MARK: Adding

    /// A new tab, selected, after the current one.
    @discardableResult
    func newTab() -> TerminalModel {
        let model = makeModel()
        register(model, as: workspace.add().pane)
        return model
    }

    /// A new terminal beside the focused one, in the same tab, with the keyboard; nil when there is no focused pane.
    @discardableResult
    func newSplit(_ edge: PaneEdge) -> TerminalModel? {
        guard let target = workspace.selectedPane else { return nil }
        let model = makeModel()
        guard let pane = workspace.addPane(beside: target, edge: edge) else { return nil }
        register(model, as: pane)
        return model
    }

    /// Takes a terminal that already runs (moved from another window when the presentation changed): a tab like any other, selected.
    func adopt(_ model: TerminalModel) { register(model, as: workspace.add().pane) }

    // MARK: Session

    /// The window as it is, for the session file: the tabs and the directory of each pane (its own report, else the one it was restored with).
    func savedWindow() -> SavedWindow {
        var directories: [PaneID: String] = [:]
        for pane in workspace.allPanes {
            if let directory = models[pane]?.directory ?? savedDirectories[pane] { directories[pane] = directory }
        }
        return SavedWindow(workspace: workspace, directories: directories)
    }

    /// Fills an empty window with a saved one: the same tabs and splits, a new terminal in each pane, started in its directory when that still exists. The
    /// terminals of tabs that are not shown start when their tab is first shown.
    func restore(_ saved: SavedWindow, directoryExists: (String) -> Bool) {
        guard workspace.isEmpty, !saved.workspace.isEmpty else { return }
        workspace = saved.workspace
        for pane in workspace.allPanes {
            let model = makeModel()
            if let directory = saved.directories[pane], directoryExists(directory) {
                model.startDirectory = directory
                savedDirectories[pane] = directory
            }
            register(model, as: pane)
        }
    }

    private func register(_ model: TerminalModel, as pane: PaneID) {
        models[pane] = model
        onChange()
        model.onExit = { [weak self] in self?.close(pane: pane) }
        // A terminal that is not shown cannot be clicked: a request from one is the window handing the keyboard back to a view that is going away (when the
        // command bar closes), and must not select its tab again.
        model.onFocusRequest = { [weak self] in
            guard let self, workspace.selectedItem?.panes.contains(pane) == true else { return }
            focus(pane)
        }
        syncStates()
    }

    // MARK: Removing

    /// Takes a pane out without stopping its program: the terminal goes to another window. The window is not told it is empty (the caller decides).
    func detach(pane: PaneID) -> TerminalModel? {
        guard let model = models[pane] else { return nil }
        workspace.close(pane: pane)
        models[pane] = nil
        syncStates()
        onChange()
        return model
    }

    func close(pane: PaneID) {
        guard let model = models[pane] else { return }
        if hoveredPane == pane { hoveredPane = nil }
        workspace.close(pane: pane)
        models[pane] = nil
        model.stop()
        finishClosing()
    }

    /// Closes a tab with all its panes.
    func close(item: Workspace.ItemID) {
        stop(workspace.close(item: item))
        finishClosing()
    }

    func closeOthers(than item: Workspace.ItemID) {
        stop(workspace.closeOthers(than: item))
        syncStates()
        onChange()
    }

    /// Closes the focused pane (the tab with its last pane).
    func closeSelected() { if let pane = workspace.selectedPane { close(pane: pane) } }

    /// Stops every program (the window is going).
    func stopAll() { for model in allModels { model.stop() } }

    private func stop(_ panes: [PaneID]) {
        for pane in panes {
            if hoveredPane == pane { hoveredPane = nil }
            models[pane]?.stop()
            models[pane] = nil
        }
    }

    private func finishClosing() {
        onChange()
        if workspace.isEmpty { onEmpty() } else { syncStates() }
    }

    // MARK: Selecting and arranging

    func select(item: Workspace.ItemID) { change { $0.select(item: item) } }
    func selectNext() { change { $0.selectNext() } }
    func selectPrevious() { change { $0.selectPrevious() } }
    func select(index: Int) { change { $0.select(index: index) } }
    func move(item: Workspace.ItemID, to index: Int) { change { $0.move(item: item, to: index) } }
    func focus(_ pane: PaneID) { change { $0.focus(pane: pane) } }
    func focusNextPane() { change { $0.focusNext() } }
    func focusPreviousPane() { change { $0.focusPrevious() } }
    func drop(item: Workspace.ItemID, onto pane: PaneID, edge: PaneEdge) {
        change { $0.drop(item: item, onto: pane, edge: edge) }
    }
    func movePane(_ pane: PaneID, beside target: PaneID, edge: PaneEdge) {
        change { $0.movePane(pane, beside: target, edge: edge) }
    }
    func detachIntoTab(_ pane: PaneID) { change { $0.detach(pane: pane) } }
    func setRatio(_ ratio: Double, at path: [SplitBranch], in item: Workspace.ItemID) {
        change { $0.setRatio(ratio, at: path, in: item) }
    }

    func change(_ edit: (inout Workspace) -> Void) {
        let before = workspace
        edit(&workspace)
        if workspace != before {
            syncStates()
            onChange()
        }
    }

    /// Tells every terminal whether it is shown (its tab is the selected one) and whether it has the keyboard (it is that tab's focused pane).
    private func syncStates() {
        let shown = Set(workspace.selectedItem?.panes ?? [])
        let focused = workspace.selectedPane
        for (pane, model) in models {
            model.paneStateChanged(focused: pane == focused, visible: shown.contains(pane))
        }
    }
}
