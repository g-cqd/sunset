package import SunsetPane

/// Tabs and windows that keep the Mac awake (roadmap 0035 E). The model says whether this window wants the Mac awake; the
/// app holds the system's assertion while one does.
extension TabsModel {
    /// Until when the tab `item` keeps the Mac awake; nil when it does not (or is not in this window any more).
    package func keepsAwake(item: Workspace.ItemID) -> KeepAwake? {
        guard workspace.items.contains(where: { $0.id == item }) else { return nil }
        return space.awake[item]
    }

    /// Keeps the tab `item` awake until `until`, or no longer (nil).
    package func keepAwake(item: Workspace.ItemID, until: KeepAwake?) {
        guard workspace.items.contains(where: { $0.id == item }) else { return }
        space.awake[item] = until
    }

    /// Keeps this window awake until `until`, or no longer (nil).
    package func keepWindowAwake(until: KeepAwake?) { windowAwake = until }

    /// Whether a command runs in the tab now: "until its command ends" has something to wait for.
    package func canKeepAwakeUntilDone(item: Workspace.ItemID) -> Bool {
        workspace.items.first { $0.id == item }.map(runsCommand) ?? false
    }

    /// Whether a command runs in one of the window's tabs now.
    package var canKeepWindowAwakeUntilDone: Bool { workspace.items.contains(where: runsCommand) }

    /// Whether this window wants the Mac awake now: kept until it is closed, or until commands end that still run; or one of its
    /// tabs is.
    package var keepsMacAwake: Bool {
        let items = workspace.items
        switch windowAwake {
            case .closed: return true
            case .commandEnds: if items.contains(where: runsCommand) { return true }
            case nil: break
        }
        return items.contains { item in
            switch space.awake[item.id] {
                case .closed: true
                case .commandEnds: runsCommand(item)
                case nil: false
            }
        }
    }

    /// Forgets what no longer applies: a tab or window kept awake until its command ended, now that it has; a tab closed.
    package func settleAwake() {
        if windowAwake == .commandEnds, !canKeepWindowAwakeUntilDone { windowAwake = nil }
        let items = Dictionary(space.tabs.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for (id, until) in space.awake {
            guard let item = items[id] else {
                space.awake[id] = nil
                continue
            }
            if until == .commandEnds, !runsCommand(item) { space.awake[id] = nil }
        }
    }

    private func runsCommand(_ item: Workspace.Item) -> Bool {
        item.panes.contains { content($0)?.runsCommand == true }
    }
}
