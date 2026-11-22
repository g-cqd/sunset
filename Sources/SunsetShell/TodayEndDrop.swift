import SunsetMetrics
import SunsetPane
import SwiftUI
import UniformTypeIdentifiers

/// After Today's last tab, while something is dragged: a row's room that takes it as the last tab, so that a tile or a
/// favourite can come back to Today even when it has no tab to be dropped beside.
struct TodayEndDrop: View {
    let tabs: TabsModel
    let layout: ShellSettings.Layout
    @State private var targeted = false

    var body: some View {
        let end = SectionDrop.today(at: tabs.workspace.count)
        Color.clear
            .frame(height: Design.oneLineHeight(layout, height: Design.Size.tabRow))
            .contentShape(.rect)
            .dropTarget(shown: tabs.canDropDragged(in: end), targeted: targeted, radius: layout.tabRadius)
            .onDrop(of: [.plainText, .utf8PlainText], isTargeted: $targeted) { _ in
                withAnimation(layout.smooth) { tabs.dropDragged(in: end) }
            }
            .accessibilityHidden(true)
    }
}
