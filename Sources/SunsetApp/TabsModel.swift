import Observation
import SunsetHost

/// The tabs of one window: the order and the selection (`TabList`) and the terminal of each. The programs belong to this store, not to a view, so the
/// presentation (built-in bar, or one tab per window with the sidebar listing them) can change while they run. A tab that is not selected is told it has no
/// focus and is not visible, so that it neither blinks nor draws.
@MainActor @Observable
final class TabsModel {
    private(set) var list = TabList()
    private(set) var models: [TabList.ID: TerminalModel] = [:]
    /// Makes and configures a terminal for a new tab (the scene knows the launch options and the configuration).
    @ObservationIgnored var makeModel: () -> TerminalModel = { TerminalModel() }
    /// The last tab was closed: the window goes.
    @ObservationIgnored var onEmpty: () -> Void = {}

    var selectedModel: TerminalModel? { list.selectedID.flatMap { models[$0] } }
    var allModels: [TerminalModel] { list.tabs.compactMap { models[$0.id] } }

    /// A new tab, selected, after the current one.
    @discardableResult
    func newTab() -> TerminalModel {
        let model = makeModel()
        let previous = selectedModel
        let id = list.add(title: "")
        models[id] = model
        model.onExit = { [weak self] in self?.close(id) }
        previous?.windowStateChanged(focused: false, visible: false)
        model.windowStateChanged(focused: true, visible: true)
        return model
    }

    /// Takes a terminal that already runs (moved from another window when the presentation changed): a tab like any other, selected.
    func adopt(_ model: TerminalModel) {
        let previous = selectedModel
        let id = list.add(title: "")
        models[id] = model
        model.onExit = { [weak self] in self?.close(id) }
        previous?.windowStateChanged(focused: false, visible: false)
        model.windowStateChanged(focused: true, visible: true)
    }

    /// Takes a tab out without stopping its program: the terminal goes to another window. The window is not told it is empty (the caller decides).
    func detach(_ id: TabList.ID) -> TerminalModel? {
        guard let model = models[id] else { return nil }
        let wasSelected = list.selectedID == id
        list.close(id)
        models[id] = nil
        if wasSelected { selectedModel?.windowStateChanged(focused: true, visible: true) }
        return model
    }

    func close(_ id: TabList.ID) {
        guard let model = models[id] else { return }
        let wasSelected = list.selectedID == id
        list.close(id)
        models[id] = nil
        model.stop()
        if list.isEmpty {
            onEmpty()
        } else if wasSelected {
            selectedModel?.windowStateChanged(focused: true, visible: true)
        }
    }

    func closeSelected() { if let id = list.selectedID { close(id) } }

    func select(_ id: TabList.ID) { change { $0.select(id: id) } }
    func selectNext() { change { $0.selectNext() } }
    func selectPrevious() { change { $0.selectPrevious() } }
    func select(index: Int) { change { $0.select(index: index) } }
    func move(_ id: TabList.ID, to index: Int) { change { $0.move(id, to: index) } }

    /// Stops every program (the window is going).
    func stopAll() { for model in allModels { model.stop() } }

    private func change(_ edit: (inout TabList) -> Void) {
        let before = list.selectedID
        edit(&list)
        guard list.selectedID != before else { return }
        if let before { models[before]?.windowStateChanged(focused: false, visible: false) }
        selectedModel?.windowStateChanged(focused: true, visible: true)
    }
}
