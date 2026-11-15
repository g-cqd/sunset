package import SwiftUI

/// The switch at the foot of the panel opposite the tabs (roadmap 0031, the owner's choice B6): a segmented row of glyphs in a
/// trough, the section shown filled. Each glyph says its name to the pointer and to VoiceOver.
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
                Button {
                    selection = section
                } label: {
                    SidebarSymbol(name: section.symbol, filled: false)
                        .foregroundStyle(shown ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: metrics.size.height - 2 * Design.Space.hair)
                        .background(
                            RoundedRectangle(
                                cornerRadius: max(metrics.radius - Design.Space.hair, 0),
                                style: .continuous
                            )
                            .fill(.primary.opacity(shown ? Design.Fill.selected : 0))
                        )
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help(section.title)
                .accessibilityLabel(section.title)
                .accessibilityAddTraits(shown ? .isSelected : [])
            }
        }
        .padding(Design.Space.hair)
        .background(
            RoundedRectangle(cornerRadius: metrics.radius, style: .continuous).fill(.primary.opacity(Design.Fill.open))
        )
        .animation(metrics.smooth, value: selection)
    }
}
