import SwiftUI

/// The container under a sidebar button's symbol, which knows whether the pointer is over it.
struct SidebarIconButtonFace<Label: View>: View {
    let label: Label
    let pressed: Bool
    let metrics: SidebarButtonMetrics
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: metrics.radius, style: .continuous)
        label
            .foregroundStyle(hovering || pressed ? .primary : .secondary)
            .frame(width: metrics.size.width, height: metrics.size.height)
            .background(shape.fill(.primary.opacity(pressed ? 0.16 : (hovering ? 0.1 : 0))))
            .contentShape(shape)
            .onHover { hovering = $0 }
            .animation(metrics.smooth, value: hovering)
    }
}
