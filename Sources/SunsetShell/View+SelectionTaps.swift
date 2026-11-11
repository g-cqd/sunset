import SwiftUI

extension View {
    /// A row's clicks (R3 step d): Cmd-click and Shift-click select rows together; a plain click runs `plain` (shows the row) after clearing the selection.
    func selectionTaps(_ tabs: TabsModel, row: RowTarget, plain: @escaping () -> Void) -> some View {
        gesture(TapGesture().modifiers(.command).onEnded { tabs.click(row, command: true, shift: false) })
            .gesture(TapGesture().modifiers(.shift).onEnded { tabs.click(row, command: false, shift: true) })
            .onTapGesture {
                tabs.click(row, command: false, shift: false)
                plain()
            }
    }
}
