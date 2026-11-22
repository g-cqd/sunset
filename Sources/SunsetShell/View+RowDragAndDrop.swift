import SunsetPane
import SwiftUI
import UniformTypeIdentifiers

extension View {
    /// A sidebar row's clicks, icon popover, drag and drop, the same for a tab's row and a favorite's (`RowDropDelegate`):
    /// `row` says which, `owner` is its id, `size` its size when known.
    func rowDragAndDrop<Owner: Equatable>(
        _ tabs: TabsModel,
        row: RowTarget,
        owner: Owner,
        size: CGSize?,
        active: Binding<(owner: Owner, place: TabDropAction)?>
    ) -> some View {
        selectionTaps(tabs, row: row) { tabs.show(row) }
            .iconPopover(tabs: tabs, row: row)
            .onDrag { tabs.itemProvider(for: row.dragPayload) }
            .onDrop(
                of: [.plainText, .utf8PlainText],
                delegate: RowDropDelegate.make(
                    owner: owner,
                    size: size ?? CGSize(width: 180, height: 32),
                    active: active,
                    accepts: { tabs.hasDrag },
                    can: { tabs.canDrop(on: row, action: $0) },
                    drop: { tabs.dropDragged(on: row, action: $0) }
                )
            )
    }
}
