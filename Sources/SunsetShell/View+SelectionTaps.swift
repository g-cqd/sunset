import SunsetPane
import SwiftUI

extension View {
    /// A row's clicks: Cmd-click and Shift-click select rows together; a plain click runs `plain` (shows the row) after
    /// clearing the selection; a double click edits the row's name in place.
    ///
    /// The double click is beside the click, not before it: a two-click gesture put first holds the click until a second one
    /// can no longer come, and every click on a row was 360 ms late (measured in `SidebarClickTests`). The first click of a
    /// double click therefore runs `plain` too. `undo` takes back what the first click of a double click did (a folder
    /// folded by it is as it was).
    func selectionTaps(
        _ tabs: TabsModel,
        row: RowTarget,
        undo: @escaping () -> Void = {},
        plain: @escaping () -> Void
    ) -> some View {
        gesture(TapGesture().modifiers(.command).onEnded { tabs.click(row, command: true, shift: false) })
            .gesture(TapGesture().modifiers(.shift).onEnded { tabs.click(row, command: false, shift: true) })
            .onTapGesture {
                tabs.click(row, command: false, shift: false)
                plain()
            }
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        undo()
                        // A kept entry away from where it was kept goes back there; anything else is renamed.
                        if case .node(let id) = row, tabs.keeper(of: id).favorites.entry(id) != nil {
                            tabs.doubleClick(entry: id)
                        } else {
                            tabs.renamingRow = row
                        }
                    }
            )
    }
}
