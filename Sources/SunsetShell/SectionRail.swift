import SunsetMetrics
package import SwiftUI

/// The Library's rail (roadmap 0031, the owner's choice L2): the sections as glyphs laid out vertically on the window's edge
/// side of the sidebar, the one shown filled; Tabs, the first, goes back to the tabs, as does the arrow at its foot, which is
/// where the Library's glyph was.
package struct SectionRail: View {
    let selection: SidebarSection
    let buttons: SidebarButtons
    let choose: (SidebarSection) -> Void

    package init(selection: SidebarSection, buttons: SidebarButtons, choose: @escaping (SidebarSection) -> Void) {
        self.selection = selection
        self.buttons = buttons
        self.choose = choose
    }

    /// How much wider the sidebar is while the rail shows: a button and its gap to the sidebar's edge. The list keeps the
    /// width the tabs have.
    package static func width(_ buttons: SidebarButtons) -> Double { buttons.metrics.size.width + buttons.gap }

    package var body: some View {
        VStack(spacing: buttons.layout.tabSpacing) {
            ForEach(SidebarSection.rail, id: \.self) { section in
                SidebarIconButton(help: section.title) {
                    choose(section)
                } label: {
                    SidebarSymbol(name: section.symbol, filled: false)
                        .foregroundStyle(section == selection ? .primary : .secondary)
                }
                .background(
                    RoundedRectangle(cornerRadius: buttons.metrics.radius, style: .continuous)
                        .fill(.primary.opacity(section == selection ? Design.Fill.selected : 0))
                )
                .accessibilityLabel(section.title)
                .accessibilityAddTraits(section == selection ? .isSelected : [])
            }
            Spacer(minLength: 0)
            SidebarIconButton(symbol: "arrow.left", help: "Back to the Tabs (Escape)") { choose(.tabs) }
                .accessibilityLabel("Back to the Tabs")
        }
        .environment(\.sidebarButtonMetrics, buttons.metrics)
        .padding(.top, buttons.header.height)
        .padding(.bottom, buttons.bottom)
    }
}
