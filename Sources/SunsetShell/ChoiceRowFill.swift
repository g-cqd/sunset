import SwiftUI

/// A choice row's label over its fill, which knows whether the pointer is over it (`ChoiceRowStyle`).
struct ChoiceRowFill<Label: View>: View {
    let label: Label
    let pressed: Bool
    let selected: Bool
    let radius: Double
    @State private var hovered = false
    @Environment(\.accent) private var accent

    var body: some View {
        label
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .onHover { hovered = $0 }
    }

    private var fill: Color {
        if selected { return accent.color.opacity(pressed ? Design.Fill.accentPressed : 1) }
        if pressed { return Color.primary.opacity(Design.Fill.pressed) }
        return Color.primary.opacity(hovered ? Design.Fill.hover : 0)
    }
}
