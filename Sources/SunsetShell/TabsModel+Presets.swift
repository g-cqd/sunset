package import SunsetPane

/// The fourth light's presets (n78, t287): the selected tab laid out at once, the tabs after it joining as panes, its extra
/// panes leaving as tabs.
extension TabsModel {
    /// Whether the selected tab and the tabs after it hold enough panes for `preset`.
    /// - Parameter preset: The shape.
    /// - Returns: True when it can be applied.
    package func canApply(_ preset: SplitPreset) -> Bool {
        guard workspace.selectedEntry == nil, let index = workspace.selectedIndex else { return false }
        return workspace.items[index...].reduce(0) { $0 + $1.panes.count } >= preset.paneCount
    }

    /// Lays the selected tab out as `preset` says; nothing when it cannot be.
    /// - Parameter preset: The shape.
    package func apply(_ preset: SplitPreset) {
        guard canApply(preset), let id = workspace.selectedID else { return }
        var tabs = workspace
        guard tabs.apply(preset, to: id) else { return }
        workspace = tabs
        syncStates()
        onChange()
    }
}
