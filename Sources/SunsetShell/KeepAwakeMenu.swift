package import SunsetPane
package import SwiftUI

/// "Keep Mac Awake" in a tab's menu, a kept entry's, or the window's (0036 C): until it is closed, or until its command
/// ends (only while one runs). The item that is on is ticked; choosing it again turns it off.
package struct KeepAwakeMenu: View {
    enum Target {
        case window
        case tab(Workspace.ItemID)
        case entry(Favorites.NodeID)
    }

    let tabs: TabsModel
    let target: Target

    /// A tab's menu; nil: the window's.
    package init(tabs: TabsModel, item: Workspace.ItemID?) {
        self.tabs = tabs
        target = item.map(Target.tab) ?? .window
    }

    /// A kept entry's menu (a favourite, a tile of the grid).
    package init(tabs: TabsModel, entry: Favorites.NodeID) {
        self.tabs = tabs
        target = .entry(entry)
    }

    private var now: KeepAwake? {
        switch target {
            case .window: tabs.windowAwake
            case .tab(let id): tabs.keepsAwake(item: id)
            case .entry(let id): tabs.keepsAwake(entry: id)
        }
    }

    private var canWait: Bool {
        switch target {
            case .window: tabs.canKeepWindowAwakeUntilDone
            case .tab(let id): tabs.canKeepAwakeUntilDone(item: id)
            case .entry(let id): tabs.canKeepAwakeUntilDone(entry: id)
        }
    }

    package var body: some View {
        let now = now
        let isWindow = if case .window = target { true } else { false }
        Menu("Keep Mac Awake") {
            Toggle(isWindow ? "Until the Window Closes" : "Until the Tab Closes", isOn: binding(.closed, now))
            Toggle(isWindow ? "Until Its Commands End" : "Until Its Command Ends", isOn: binding(.commandEnds, now))
                .disabled(now != .commandEnds && !canWait)
        }
    }

    private func binding(_ until: KeepAwake, _ now: KeepAwake?) -> Binding<Bool> {
        Binding(
            get: { now == until },
            set: { on in
                let next = on ? until : nil
                switch target {
                    case .window: tabs.keepWindowAwake(until: next)
                    case .tab(let id): tabs.keepAwake(item: id, until: next)
                    case .entry(let id): tabs.keepAwake(entry: id, until: next)
                }
            }
        )
    }
}
