import SunsetMetrics
import SwiftUI

/// What lies at a row's end: the edited mark, the close button and the controls after it, and where its title stops.
extension SidebarRow {
    /// A document with edits that are not saved: the row says so at its end, and the title stops before it.
    var edited: Bool {
        model?.isEdited == true && renaming == nil
    }

    /// The row's end with the close button shown or not.
    func rowEnd(closeShown: Bool) -> RowEnd {
        RowEnd(
            size: layout.closeButtonSize,
            gap: Design.Space.xs,
            closeShown: closeShown,
            controls: endControls.count,
            edited: edited,
            markWidth: Design.Size.editedMark,
            leading: layout.tabPaddingLeading,
            trailing: layout.tabPaddingTrailing
        )
    }

    /// What the title leaves free at the row's end: the shown button's place, the controls', the mark's, or nothing.
    var titleEnd: Double {
        rowEnd(closeShown: showsClose && renaming == nil).titleEnd
    }
}
