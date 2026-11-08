import SunsetConfig
import SwiftUI

/// The button that pins the sidebar. One rounded square is both what is drawn and what takes the click (`contentShape`), so the hit box is exactly the
/// container, with no dead edge around the symbol.
struct PinButton: View {
    let pinned: Bool
    let layout: Configuration.Layout
    let radius: Double
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Button(action: action) {
            Image(systemName: "sidebar.left")
                .symbolVariant(pinned ? .fill : .none)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(hovering ? .primary : .secondary)
                .frame(width: layout.pinButtonSize, height: layout.pinButtonSize)
                .background(shape.fill(.primary.opacity(hovering ? 0.1 : 0)))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: pinned)
        .help(pinned ? "Let the sidebar hide" : "Keep the sidebar visible")
    }
}
