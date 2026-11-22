import SunsetMetrics
import SunsetShell
import SwiftUI

/// A row of the Library's lists (a document, a page of the history): a tab row's paddings and height for its lines, its
/// rounded fill, and the hover it keeps through menus.
struct LibraryRowFrame: ViewModifier {
    let layout: ShellSettings.Layout
    let lines: Int
    let fill: Double
    @Binding var hovered: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        content
            .padding(.leading, layout.tabPaddingLeading)
            .padding(.trailing, layout.tabPaddingTrailing)
            .padding(.vertical, Design.rowPadding(layout, lines: lines, height: Design.Size.tabRow))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(Color.primary.opacity(fill)))
            .contentShape(shape)
            .animation(layout.smooth, value: hovered)
            .keptHover($hovered)
    }
}
