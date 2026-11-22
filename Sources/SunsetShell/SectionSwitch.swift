package import SwiftUI

/// The switch at the foot of the panel opposite the tabs: a glyph button for each section, drawn as the buttons of the
/// tabs' sidebar's foot (`SidebarIconButton`), centred as its Spaces; the section shown has the selected tab's white fill
/// and ink.
package struct SectionSwitch: View {
    let sections: [SidebarSection]
    @Binding var selection: SidebarSection
    @Environment(\.sidebarButtonMetrics) private var metrics

    package init(sections: [SidebarSection] = SidebarSection.panel, selection: Binding<SidebarSection>) {
        self.sections = sections
        _selection = selection
    }

    package var body: some View {
        HStack(spacing: Design.Space.hair) {
            ForEach(sections, id: \.self) { section in
                let shown = section == selection
                SidebarIconButton(help: section.title, action: { selection = section }) {
                    // Inside the face, whose own colour is the bar's: the shown one white.
                    SidebarSymbol(name: section.symbol)
                        .foregroundStyle(shown ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                }
                .background(
                    Color.primary.opacity(shown ? Design.Fill.selected : 0),
                    in: .rect(cornerRadius: metrics.radius, style: .continuous)
                )
                .accessibilityLabel(section.title)
                .accessibilityAddTraits(shown ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: metrics.size.height)
        .animation(metrics.smooth, value: selection)
    }
}
