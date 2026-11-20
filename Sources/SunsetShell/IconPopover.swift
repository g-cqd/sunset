import SunsetPane
package import SwiftUI

/// The icon of a tab, an entry or a folder (R3 step c): the picker, applied to the row as it is picked.
package struct IconPopover: View {
    let tabs: TabsModel
    let row: RowTarget

    package init(tabs: TabsModel, row: RowTarget) {
        self.tabs = tabs
        self.row = row
    }

    package var body: some View {
        IconPicker(
            icon: Binding(get: { tabs.icon(of: row) }, set: { tabs.setIcon($0, for: row) }),
            clearTitle: tabs.clearIconTitle(for: row)
        )
        .padding(Design.Space.xl)
        .frame(width: 340)
        .solidPopoverBackground()
    }
}
