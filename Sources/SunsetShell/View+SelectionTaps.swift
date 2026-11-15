import SwiftUI

extension View {
    /// A row's clicks (R3 step d): Cmd-click and Shift-click select rows together; a plain click runs `plain` (shows the row) after
    /// clearing the selection; a double click edits the row's name in place.
    ///
    /// The double click is beside the click, not before it: a two-click gesture put first holds the click until a second one
    /// can no longer come, and every click on a row was 360 ms late (measured in `SidebarClickTests`; owner notes n15, n56,
    /// n59). The first click of a double click therefore runs `plain` too.
    func selectionTaps(_ tabs: TabsModel, row: RowTarget, plain: @escaping () -> Void) -> some View {
        gesture(TapGesture().modifiers(.command).onEnded { tabs.click(row, command: true, shift: false) })
            .gesture(TapGesture().modifiers(.shift).onEnded { tabs.click(row, command: false, shift: true) })
            .onTapGesture {
                tabs.click(row, command: false, shift: false)
                plain()
            }
            .simultaneousGesture(TapGesture(count: 2).onEnded { tabs.renamingRow = row })
    }
}
