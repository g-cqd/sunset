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

    /// Until when the kept entry `id` keeps the Mac awake; nil when it does not.
    package func keepsAwake(entry id: Favorites.NodeID) -> KeepAwake? { keeper(of: id).awake[id] }

    /// Keeps the kept entry `id` awake until `until`, or no longer (nil); it lets go when it is unloaded (roadmap 0036 C).
    package func keepAwake(entry id: Favorites.NodeID, until: KeepAwake?) {
        let keeper = keeper(of: id)
        guard keeper.favorites.entry(id) != nil else { return }
        keeper.awake[id] = until
    }

    /// Whether a command runs in the kept entry now.
    package func canKeepAwakeUntilDone(entry id: Favorites.NodeID) -> Bool {
        keeper(of: id).favorites.entry(id)?.open.map(runsCommand) ?? false
    }

    /// The kept entries (Favorites, Pinned) that want the Mac awake now: open, and kept until closed or running a command.
    private var keptKeepAwake: Bool {
        [favorites, pinned].compactMap { $0 }
            .contains { keeper in
                keeper.awake.contains { id, until in
                    guard let open = keeper.favorites.entry(id)?.open else { return false }
                    return until == .closed || runsCommand(open)
                }
            }
    }

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
        if keptKeepAwake { return true }
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
        settleKeptAwake()
        let items = Dictionary(space.tabs.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for (id, until) in space.awake {
            guard let item = items[id] else {
                space.awake[id] = nil
                continue
            }
            if until == .commandEnds, !runsCommand(item) { space.awake[id] = nil }
        }
    }

    /// Forgets the kept entries that were closed (unloaded, deleted), or kept until a command that has ended.
    private func settleKeptAwake() {
        for keeper in [favorites, pinned].compactMap({ $0 }) {
            for (id, until) in keeper.awake {
                guard let open = keeper.favorites.entry(id)?.open else {
                    keeper.awake[id] = nil
                    continue
                }
                if until == .commandEnds, !runsCommand(open) { keeper.awake[id] = nil }
            }
        }
    }

    private func runsCommand(_ item: Workspace.Item) -> Bool {
        item.panes.contains { content($0)?.runsCommand == true }
    }
}
