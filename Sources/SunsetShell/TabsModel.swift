import Foundation
package import Observation
package import SunsetPane

/// The tabs of one window: their order, the selection and the split of each (`Workspace`), and the content of each pane (`PaneContent`: a terminal, a
/// note). The contents belong to this store, not to a view, so the presentation (built-in bar, or one tab per window with the sidebar listing them) can
/// change while they run. A pane that is not shown is told it has no focus and is not visible, so that it neither blinks nor draws; of the shown panes
/// only the focused one blinks.
@MainActor @Observable
package final class TabsModel {
    package private(set) var workspace = Workspace()
    package private(set) var contents: [PaneID: any PaneContent] = [:]
    /// Makes the content of a pane: the app's default kind for nil, else what the descriptor says. Until the app says how, a pane is a placeholder.
    @ObservationIgnored package var makeContent: (PaneDescriptor?) -> any PaneContent = {
        UnknownContent($0 ?? PaneDescriptor(kind: ""))
    }
    /// The last tab was closed: the window goes.
    @ObservationIgnored package var onEmpty: () -> Void = {}
    /// The tabs changed (added, closed, moved, split, selected): the session is to be saved.
    @ObservationIgnored package var onChange: () -> Void = {}
    /// What a sidebar or bar drag in this window carries, from its start until it is dropped (set when the drag begins; see `beginDrag`).
    @ObservationIgnored package var dragged: PaneDragPayload?
    /// The command bar, when it is open: searching the tabs, or (after the selected tab was dropped on its own content) choosing the tab to split with.
    package var bar: CommandBar?
    /// This window's temporary font size change (⌘+, ⌘−, ⌘0).
    package var fontZoom = FontZoom()
    /// The pane whose sub-tab is currently under the pointer in a split container (`SidebarGroupRow`), so its terminal card can highlight its stroke.
    package var hoveredPane: PaneID?
    /// The tab row currently under the pointer in the sidebar or tab bar, so an unselected tab can show a screen preview (`n36`).
    package var hoveredItem: Workspace.ItemID?
    /// The tab being renamed, while its dialog is open (`RenameTabAlert`).
    package var renaming: Workspace.ItemID?
    /// Two-step confirmation before closing a tab that has a command running (`n28`).
    package var closeConfirmation = CloseConfirmation()
    /// Whether closing a busy tab requires a second click or ⌘W (`tabs.confirmClose`).
    package var confirmClose = true
    @ObservationIgnored private var expiryTask: Task<Void, Never>?

    package init() {}

    package var selectedContent: (any PaneContent)? { workspace.selectedPane.flatMap { contents[$0] } }

    // MARK: Adding

    /// A new tab, selected, after the current one: a terminal, or what `descriptor` says.
    package func newTab(_ descriptor: PaneDescriptor? = nil) {
        register(makeContent(descriptor), as: workspace.add().pane)
    }

    /// A new terminal beside the focused pane, in the same tab, with the keyboard; nothing when there is no focused pane.
    package func newSplit(_ edge: PaneEdge) {
        guard let target = workspace.selectedPane, let pane = workspace.addPane(beside: target, edge: edge) else {
            return
        }
        register(makeContent(nil), as: pane)
    }

    /// Takes content that already runs (moved from another window when the presentation changed): a tab like any other, selected.
    package func adopt(_ content: any PaneContent) { register(content, as: workspace.add().pane) }

    // MARK: Session

    /// The window as it is, for the session file: the tabs and what brings the content of each pane back.
    package func savedWindow() -> SavedWindow {
        SavedWindow(workspace: workspace, contents: contents.mapValues(\.descriptor))
    }

    /// Fills an empty window with a saved one: the same tabs and splits, and in each pane the content its descriptor says (a new terminal in its
    /// directory, a note with its text). The terminals of tabs that are not shown start when their tab is first shown.
    package func restore(_ saved: SavedWindow) {
        guard workspace.isEmpty else { return }
        // A saved window may have no tab of its own (it showed a kept entry, which no window shows yet): it starts with a new tab.
        guard !saved.workspace.isEmpty else { return newTab() }
        workspace = saved.workspace
        for pane in workspace.allPanes {
            register(makeContent(saved.contents[pane] ?? .terminal(directory: nil)), as: pane)
        }
    }

    private func register(_ model: any PaneContent, as pane: PaneID) {
        contents[pane] = model
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

    /// User-initiated request to close a pane: when a command is running in it, arms its tab for confirmation first (`n28`).
    package func requestClose(pane: PaneID) {
        guard let item = workspace.item(containing: pane)?.id, let model = contents[pane] else { return }
        guard confirmed(.pane(pane, in: item), isBusy: model.closeWarning != nil) else { return }
        close(pane: pane)
    }

    /// Closes a tab with all its panes (asking for confirmation first when any of its panes has a command running).
    package func close(item: Workspace.ItemID) {
        if hoveredItem == item { hoveredItem = nil }
        guard let target = workspace.items.first(where: { $0.id == item }) else { return }
        guard confirmed(.item(item), isBusy: target.panes.contains { contents[$0]?.closeWarning != nil }) else {
            return
        }
        stop(workspace.close(item: item))
        finishClosing()
    }

    /// Whether `item` is currently armed for close confirmation (tinted red).
    package func isCloseArmed(_ item: Workspace.ItemID) -> Bool {
        closeConfirmation.isArmed(item: item, now: .now)
    }

    private func confirmed(_ target: CloseConfirmation.Target, isBusy: Bool) -> Bool {
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

    /// Closes every tab but `item`, asking first when a command is running in one of them (they go red).
    package func closeOthers(than item: Workspace.ItemID) {
        let others = workspace.items.filter { $0.id != item }.flatMap(\.panes)
        guard confirmed(.others(item), isBusy: others.contains { contents[$0]?.closeWarning != nil }) else { return }
        stop(workspace.closeOthers(than: item))
        syncStates()
        onChange()
    }

    /// Closes the focused pane (the tab with its last pane).
    package func closeSelected() { if let pane = workspace.selectedPane { requestClose(pane: pane) } }

    /// Stops every program (the window is going).
    package func stopAll() { for content in contents.values { content.stop() } }

    private func stop(_ panes: [PaneID]) {
        for pane in panes {
            if hoveredPane == pane { hoveredPane = nil }
            contents[pane]?.stop()
            contents[pane] = nil
        }
    }

    private func finishClosing() {
        onChange()
        if workspace.isEmpty { onEmpty() } else { syncStates() }
    }

    // MARK: Selecting and arranging

    package func select(item: Workspace.ItemID) {
        if hoveredItem == item { hoveredItem = nil }
        change { $0.select(item: item) }
    }
    package func selectNext() { change { $0.selectNext() } }
    package func selectPrevious() { change { $0.selectPrevious() } }
    package func select(index: Int) { change { $0.select(index: index) } }
    package func move(item: Workspace.ItemID, to index: Int) { change { $0.move(item: item, to: index) } }
    package func focus(_ pane: PaneID) { change { $0.focus(pane: pane) } }
    package func focusNextPane() { change { $0.focusNext() } }
    package func focusPreviousPane() { change { $0.focusPrevious() } }
    package func drop(item: Workspace.ItemID, onto pane: PaneID, edge: PaneEdge) {
        change { $0.drop(item: item, onto: pane, edge: edge) }
    }
    package func movePane(_ pane: PaneID, beside target: PaneID, edge: PaneEdge) {
        change { $0.movePane(pane, beside: target, edge: edge) }
    }
    package func detachIntoTab(_ pane: PaneID) { change { $0.detach(pane: pane) } }
    package func setRatio(_ ratio: Double, at path: [SplitBranch], in item: Workspace.ItemID) {
        change { $0.setRatio(ratio, at: path, in: item) }
    }

    package func change(_ edit: (inout Workspace) -> Void) {
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
        for (pane, content) in contents {
            content.setState(focused: pane == focused, visible: shown.contains(pane))
        }
    }
}
