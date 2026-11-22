import SunsetMetrics
import SunsetPane
import SwiftUI

/// A split's row in the sidebar, a tab's or a kept entry's (both drew it whole): its own name and icon when it has any,
/// above its panes side by side, in a rounded frame filled and outlined as the row says; the same small inset around the
/// panes and between them, so that their corners nest in the row's.
struct GroupFrame<Parts: View, Outline: View>: View {
    let name: String?
    let icon: PaneIcon?
    let layout: ShellSettings.Layout
    let fill: Color
    @ViewBuilder let parts: () -> Parts
    @ViewBuilder let outline: (RoundedRectangle) -> Outline

    /// The space between the frame and its panes, and between two panes.
    static var inset: Double {
        Design.Space.hair
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        VStack(alignment: .leading, spacing: Self.inset) {
            if name != nil || icon != nil {
                HStack(spacing: Design.Space.xs) {
                    if let icon {
                        PaneIconView(icon: icon)
                    }
                    if let name {
                        Text(name).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .padding(.horizontal, Design.Space.s)
            }
            HStack(spacing: Self.inset) {
                parts()
            }
        }
        .padding(Self.inset)
        .background(shape.fill(fill))
        .overlay {
            outline(shape)
        }
        .contentShape(shape)
    }
}
