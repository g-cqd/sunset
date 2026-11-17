package import SunsetPane

/// Tabs and windows that keep the Mac awake (roadmap 0035 E). The model says whether this window wants the Mac awake; the
/// app holds the system's assertion while one does.
extension TabsModel {
    private var awake: KeepAwakePanes { KeepAwakePanes.shared }

    /// Until when the tab `item` keeps the Mac awake; nil when it does not (or is not in this window any more).
    package func keepsAwake(item: Workspace.ItemID) -> KeepAwake? {
        workspace.items.first { $0.id == item }.flatMap { awake.until($0.panes) }
    }

    /// Keeps the tab `item` awake until `until`, or no longer (nil).
    package func keepAwake(item: Workspace.ItemID, until: KeepAwake?) {
        guard let item = workspace.items.first(where: { $0.id == item }) else { return }
        awake.set(until, for: item.panes)
    }

    /// Keeps this window awake until `until`, or no longer (nil).
    package func keepWindowAwake(until: KeepAwake?) { windowAwake = until }

    /// Until when the kept entry `id` keeps the Mac awake, while it is open; nil when it does not.
    package func keepsAwake(entry id: Favorites.NodeID) -> KeepAwake? {
        keeper(of: id).favorites.entry(id)?.open.flatMap { awake.until($0.panes) }
    }

    /// Keeps the kept entry `id` awake until `until`, or no longer (nil); it lets go when it is unloaded (roadmap 0036 C).
    package func keepAwake(entry id: Favorites.NodeID, until: KeepAwake?) {
        guard let open = keeper(of: id).favorites.entry(id)?.open else { return }
        awake.set(until, for: open.panes)
    }

    /// Whether a command runs in the kept entry now.
    package func canKeepAwakeUntilDone(entry id: Favorites.NodeID) -> Bool {
        keeper(of: id).favorites.entry(id)?.open.map(runsCommand) ?? false
    }

    /// Whether a command runs in the tab now: "until its command ends" has something to wait for.
    package func canKeepAwakeUntilDone(item: Workspace.ItemID) -> Bool {
        workspace.items.first { $0.id == item }.map(runsCommand) ?? false
    }

    /// Whether a command runs in one of the window's tabs now.
    package var canKeepWindowAwakeUntilDone: Bool { workspace.items.contains(where: runsCommand) }

    /// What this window shows that is running: its tabs, and the open entries of its Favorites and grid.
    private var runningItems: [Workspace.Item] {
        workspace.items + [favorites, pinned].compactMap { $0 }.flatMap { $0.favorites.entries.compactMap(\.open) }
    }

    /// Whether this window wants the Mac awake now: kept until it is closed, or until commands end that still run; or one of its
    /// tabs, or open kept entries, is.
    package var keepsMacAwake: Bool {
        switch windowAwake {
            case .closed: return true
            case .commandEnds: if workspace.items.contains(where: runsCommand) { return true }
            case nil: break
        }
        return runningItems.contains { item in
            switch awake.until(item.panes) {
                case .closed: true
                case .commandEnds: runsCommand(item)
                case nil: false
            }
        }
    }

    /// Forgets what no longer applies, for this window alone (`settleAwake(in:)`).
    package func settleAwake() { Self.settleAwake(in: [self]) }

    /// Forgets what no longer applies, the app's windows given: a window kept awake until its commands ended, now that they
    /// have; what is kept awake of a pane that runs in none of them any more (closed, unloaded), or until a command that has
    /// ended.
    package static func settleAwake(in windows: [TabsModel]) {
        for window in windows where window.windowAwake == .commandEnds && !window.canKeepWindowAwakeUntilDone {
            window.windowAwake = nil
        }
        let store = KeepAwakePanes.shared
        let items = windows.flatMap { $0.runningItems }
        var running: [PaneID: Workspace.Item] = [:]
        for item in items {
            for pane in item.panes { running[pane] = item }
        }
        for (pane, until) in store.until {
            guard let item = running[pane], let window = windows.first(where: { $0.content(pane) != nil }) else {
                if running[pane] == nil { store.until[pane] = nil }
                continue
            }
            if until == .commandEnds, !window.runsCommand(item) { store.until[pane] = nil }
        }
    }

    func runsCommand(_ item: Workspace.Item) -> Bool {
        item.panes.contains { content($0)?.runsCommand == true }
    }
}
