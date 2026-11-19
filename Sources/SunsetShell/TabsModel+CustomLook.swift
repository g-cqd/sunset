package import SunsetPane
import SwiftUI

/// What a row shows of a tab's own look: a drawing question (whether the system has the symbol), so the views'.
extension TabsModel {
    /// The tab's name and icon as the rows show them: nil where the tab has none of its own, or an icon the system cannot draw.
    package func custom(for item: Workspace.Item) -> (name: String?, icon: PaneIcon?) {
        (item.customTitle, item.customIcon.flatMap { PaneIconView.canShow($0) ? $0 : nil })
    }
}
