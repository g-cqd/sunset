import SwiftUI

/// Sets the accent for everything below, Sunset's parts (`\.accent`) and the system's controls (`tint`), in the scheme the views are drawn in.
struct AccentModifier: ViewModifier {
    let accent: Design.Accent
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let style = accent.style(dark: scheme == .dark)
        content.environment(\.accent, style).tint(style.color)
    }
}
