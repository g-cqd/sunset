package import SwiftUI

/// A title that shows or hides what is under it, for a popover's groups: its content as wide as the popover, where a
/// `DisclosureGroup` indents it past its arrow. The title and the arrow are one button.
package struct Fold<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    package init(_ title: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        _isExpanded = isExpanded
        self.content = content
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Button {
                withAnimation(.easeOut(duration: Design.Motion.foldDuration)) { isExpanded.toggle() }
            } label: {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: "chevron.right")
                        .font(Design.Text.detail.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .labelStyle(.row)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            if isExpanded {
                content().frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
