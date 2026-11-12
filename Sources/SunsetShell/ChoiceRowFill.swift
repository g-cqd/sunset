import SwiftUI

/// A choice row's label over its fill, which knows whether the pointer is over it (`ChoiceRowStyle`).
struct ChoiceRowFill<Label: View>: View {
    let label: Label
    let pressed: Bool
    let selected: Bool
    let radius: Double
    @State private var hovered = false

    var body: some View {
        label
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .onHover { hovered = $0 }
    }

    private var fill: Color {
        if selected { return Color.accentColor.opacity(pressed ? 0.8 : 1) }
        if pressed { return Color.primary.opacity(0.16) }
        return Color.primary.opacity(hovered ? 0.07 : 0)
    }
}
