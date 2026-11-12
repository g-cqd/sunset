import SwiftUI

/// The look of `SidebarIconButton`.
struct SidebarIconButtonStyle: ButtonStyle {
    let metrics: SidebarButtonMetrics

    func makeBody(configuration: Configuration) -> some View {
        SidebarIconButtonFace(label: configuration.label, pressed: configuration.isPressed, metrics: metrics)
    }
}
