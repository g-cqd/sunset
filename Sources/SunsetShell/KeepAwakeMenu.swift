package import SunsetPane
package import SwiftUI

/// "Keep Mac Awake" in a tab's menu, or the window's (roadmap 0035 E): until it is closed, or until its command ends (only
/// while one runs). The item that is on is ticked; choosing it again turns it off.
package struct KeepAwakeMenu: View {
    let tabs: TabsModel
    /// The tab; nil for the window.
    let item: Workspace.ItemID?

    package init(tabs: TabsModel, item: Workspace.ItemID?) {
        self.tabs = tabs
        self.item = item
    }

    package var body: some View {
        let now = item.map { tabs.keepsAwake(item: $0) } ?? tabs.windowAwake
        let canWait = item.map { tabs.canKeepAwakeUntilDone(item: $0) } ?? tabs.canKeepWindowAwakeUntilDone
        Menu("Keep Mac Awake") {
            Toggle(item == nil ? "Until the Window Closes" : "Until the Tab Closes", isOn: binding(.closed, now))
            Toggle(item == nil ? "Until Its Commands End" : "Until Its Command Ends", isOn: binding(.commandEnds, now))
                .disabled(now != .commandEnds && !canWait)
        }
    }

    private func binding(_ until: KeepAwake, _ now: KeepAwake?) -> Binding<Bool> {
        Binding(
            get: { now == until },
            set: { on in
                let next = on ? until : nil
                if let item { tabs.keepAwake(item: item, until: next) } else { tabs.keepWindowAwake(until: next) }
            }
        )
    }
}
