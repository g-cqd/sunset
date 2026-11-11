import SwiftUI

extension View {
    /// The icon popover of `row`, shown beside it while it is the row whose icon is being chosen.
    func iconPopover(tabs: TabsModel, row: RowTarget) -> some View {
        popover(
            isPresented: Binding(
                get: { tabs.iconRow == row },
                set: { if !$0, tabs.iconRow == row { tabs.iconRow = nil } }
            ),
            arrowEdge: .trailing
        ) { IconPopover(tabs: tabs, row: row) }
    }
}
